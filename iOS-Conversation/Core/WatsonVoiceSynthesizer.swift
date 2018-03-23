//
//  VoiceSynthesizer.swift
//  Watson Conversation
//
//  Created by Marco Aurélio Bigélli Cardoso on 20/01/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire
import AudioToolbox
import IBMMobileFirstPlatformFoundation

class WatsonVoiceSynthesizer: NSObject, VoiceSynthesizer {
    // Delegate to receive callbacks:
    weak var delegate: VoiceSynthesizerDelegate?
    
    // Reference to audio player
    private var player: AVAudioPlayer?
    
    private var cacheOn = true
    private let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/"
    var cancelled = false
//    var currentRequest: DataRequest?
    
    private let problemWords: [String : String] = [
        "ibm": "i b m"
    ]
    
    private var synthQueue = [String]()
    
    // Gets audio data for text. Tries cache first, and adds to cache if that fails
    func synthesize(text: String) {
        delegate?.onSynthesisStart()
        
        if text == "" {
            delegate?.onSynthesisSuccess(audio: Data()) // Empty data for empty string
            return
        }
        
        let processedText = prepareForSynthesis(text)
        
        if let data = dataFromCache(message: processedText) {
            delegate?.onSynthesisSuccess(audio: data)
            return
        }
        
        actuallySynthesize(processedText, completion: { data in
//            if data != nil {
                self.delegate?.onSynthesisSuccess(audio: data)
//            } else {
//                self.delegate?.onSynthesisError(errorDescription: "No audio data returned")
//            }
        })
    }
    
    // Stops ongoing download immediately.
    func cancel() {
        cancelled = true
        cacheOn = false
//        currentRequest?.cancel()
        delegate?.onSynthesisSuccess(audio: Data())
    }
    
    // Synthesizes a bunch of messages and saves to cache
    func massSynthesize(texts: [String]) {
        var msgCount = 0
        for text in texts {
            textToData(text, completion: { _ in
                msgCount += 1
                if msgCount == texts.count {
                    self.delegate?.didFinishMassSynthesize()
                }
            })
        }
    }
    
    // Same as synthesize but with closure
    private func textToData(_ text: String, completion: @escaping (Data?) -> (Void)) {
        if text == "" {
            completion(nil)
            return
        }
        
        let processedText = prepareForSynthesis(text)
        
        if let data = dataFromCache(message: processedText) {
            completion(data)
            return
        }
        
        actuallySynthesize(processedText, completion: { data in
            completion(data)
        })
    }
    
    // Activate Watson Text-to-Speech API for audio synthesis
    private func actuallySynthesize(_ text: String, completion: @escaping (Data) -> (Void)) {
        let _ = WLClient.sharedInstance().serverUrl()
        
        if let _ = Settings.accessToken {
            self.startActuallySynthesizeOfText(text, completion: completion)
        }else {
            WLAuthorizationManager.sharedInstance().obtainAccessToken(forScope: "RegisteredClient") { (token, error) in
                
                if let error = error {
                    print("Não foi recebido um Token do servidor: " + error.localizedDescription)
                    self.delegate?.onSynthesisError(errorDescription: error.localizedDescription)
                }else {
                    self.startActuallySynthesizeOfText(text, completion: completion)
                }
            }
        }
    }
    private func startActuallySynthesizeOfText(_ text: String, completion: @escaping (Data) -> (Void)) {
        
        let requestURL = Settings.voiceSynthesisURL
        let user = Settings.voiceSynthesisUsername
        let password = Settings.voiceSynthesisPassword
        
        let request = WLResourceRequest(url: URL(string: requestURL), method: WLHttpMethodPost)
        
        var authorizationValue = ""
        if let authorizationHeader = Request.authorizationHeader(user: user, password: password) {
            
            authorizationValue = authorizationHeader.value
            request?.setHeaderValue("audio/wav" as NSObject, forName: "Accept")
            request?.setHeaderValue("application/json" as NSObject, forName: "Content-Type")
        }
        
        let requestParams = [
            "authorization" : authorizationValue,
            "text": text
        ]
        
        request?.send(withJSON: requestParams, completionHandler: { (response, error) in
            if let error = error {
                print("Failure: " + error.localizedDescription)
                self.delegate?.onSynthesisError(errorDescription: error.localizedDescription)
            }else {
                
                if let response = response {
                    
                    if response.status == 200 {
                        if let audio = response.responseData {
                            var wav = audio
                            self.repairWAVHeader(data: &wav)
                            if self.cacheOn {
                                self.dataToCache(message: text, data: wav)
                            }
                            completion(wav)
                        } else {
                            self.delegate?.onSynthesisError(errorDescription: "No data returned from server")
                        }
                        
                        // Turn cache back on (if this callback was from cancelling a download)
                        self.cacheOn = true
                    } else {
                        self.delegate?.onSynthesisError(errorDescription: "Server responded with " + response.error.localizedDescription)
                    }
                }
            }
        })
    }
    
    // Processes text for text-to-speech. Lowercase and swap problem words
    private func prepareForSynthesis(_ text: String) -> String {
        var output = text.lowercased()
        for (problemWord, fixedWord) in problemWords {
            output = output.replacingOccurrences(of: problemWord, with: fixedWord)
        }
        
        output =
            output.replacingOccurrences(of: "\\s?[+][=](.*?)[=][+]", with: "", options: .regularExpression, range: nil)
        
        output = output.replacingOccurrences(of: "-=", with: "")
        output = output.replacingOccurrences(of: "=-", with: "")
        
        return output
    }
    
    private func dataFromCache(message: String) -> Data? {
        let prefix = Settings.textToSpeechVoice
        let finalPath = self.documentsPath + String(prefix.hash) + "_" + String(message.hash) + ".wav"
        let input = FileHandle(forReadingAtPath: finalPath)
        if (input == nil) {
            return nil
        }
        let data = input?.readDataToEndOfFile()
        input?.closeFile()
        return data
    }
    
    private func dataToCache(message: String, data: Data) {
        let prefix = Settings.textToSpeechVoice
        let finalPath = self.documentsPath + String(prefix.hash) + "_" + String(message.hash) + ".wav"
        FileManager.default.createFile(atPath: finalPath, contents: data, attributes: nil)        
    }
    
    // Three functions from WDC to repair WAV header:
    func repairWAVHeader(data: inout Data) {
        
        // resources for WAV header format:
        // [1] http://unusedino.de/ec64/technical/formats/wav.html
        // [2] http://soundfile.sapp.org/doc/WaveFormat/
        
        // update RIFF chunk size
        let fileLength = data.count
        var riffChunkSize = UInt32(fileLength - 8)
        let riffChunkSizeData = Data(bytes: &riffChunkSize, count: MemoryLayout<UInt32>.stride)
        data.replaceSubrange(Range(uncheckedBounds: (lower: 4, upper: 8)), with: riffChunkSizeData)
        
        // find data subchunk
        var subchunkID: String?
        var subchunkSize = 0
        var fieldOffset = 12
        let fieldSize = 4
        while true {
            // prevent running off the end of the byte buffer
            if fieldOffset + 2*fieldSize >= data.count {
                return
            }
            
            // read subchunk ID
            subchunkID = dataToUTF8String(data: data, offset: fieldOffset, length: fieldSize)
            fieldOffset += fieldSize
            if subchunkID == "data" {
                break
            }
            
            // read subchunk size
            subchunkSize = dataToUInt32(data: data, offset: fieldOffset)
            fieldOffset += fieldSize + subchunkSize
        }
        
        // compute data subchunk size (excludes id and size fields)
        var dataSubchunkSize = UInt32(data.count - fieldOffset - fieldSize)
        
        // update data subchunk size
        let dataSubchunkSizeData = Data(bytes: &dataSubchunkSize, count: MemoryLayout<UInt32>.stride)
        data.replaceSubrange(Range(uncheckedBounds: (lower: fieldOffset, upper: fieldOffset+fieldSize)), with: dataSubchunkSizeData)
    }
    
    func dataToUTF8String(data: Data, offset: Int, length: Int) -> String? {
        let range = Range(uncheckedBounds: (lower: offset, upper: offset + length))
        let subdata = data.subdata(in: range)
        return String(data: subdata, encoding: String.Encoding.utf8)
    }
    
    func dataToUInt32(data: Data, offset: Int) -> Int {
        var num: UInt8 = 0
        let length = 4
        let range = Range(uncheckedBounds: (lower: offset, upper: offset + length))
        data.copyBytes(to: &num, from: range)
        return Int(num)
    }
    
}
