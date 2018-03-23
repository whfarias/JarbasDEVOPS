//
//  LiveUpdate.swift
//  Conversation MF
//
//  Created by Rafael Moris on 04/07/17.
//  Copyright © 2017 Marco Aurélio Bigélli Cardoso. All rights reserved.
//

import Foundation
import IBMMobileFirstPlatformFoundation
import IBMMobileFirstPlatformFoundationLiveUpdate

class LiveUpdate {
    static let shared = LiveUpdate()
    
    fileprivate init() {
        if UserDefaults.standard.bool(forKey: kLiveUpdateWasModified) == false {
            UserDefaults.standard.set(true, forKey: kFeatureVoiceMessage)
            UserDefaults.standard.set(true, forKey: kFeatureVisualRecognition)
        }
    }
    
    var currentBackground:String {
        get {
            if let background = UserDefaults.standard.string(forKey: kLiveUpdateCurrentBackground) {
                return background
            }
            return kLiveUpdateInitialBackground
        }
    }
    
    var settingsIsHidden:Bool {
        get {
            if let settings = UserDefaults.standard.string(forKey: kLiveUpdateSettingsIsHidden) {
                return settings == "true"
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue == true ? "true" : "false", forKey: kLiveUpdateSettingsIsHidden)
            UserDefaults.standard.synchronize()
        }
    }
    
    private var currentSegment:String {
        get {
            
            let voice = UserDefaults.standard.bool(forKey: kFeatureVoiceMessage)
            let text = UserDefaults.standard.bool(forKey: kFeatureTextMessage)
            let visual = UserDefaults.standard.bool(forKey: kFeatureVisualRecognition)
            
            if voice && text && visual {
                return kSegmentHaveEverything
            }else if voice && text && !visual {
                return kSegmentVoiceText
            }else if voice && !text && visual {
                return kSegmentVoiceVisual
            }else if voice && !text && !visual {
                return kSegmentVoiceOnly
            }else if !voice && text && visual {
                return kSegmentTextVisual
            }else if !voice && text && !visual {
                return kSegmentTextOnly
            }
            
            return kInitialSegment
        }
    }
    
    func setValue(_ value:Bool, forFeatureKey feature:String) {
        UserDefaults.standard.set(value, forKey: feature)
        UserDefaults.standard.set(true, forKey: kLiveUpdateWasModified)
        UserDefaults.standard.synchronize()
    }
    
    func setValue(_ value:Any?, forPropertyKey property:String) {
        UserDefaults.standard.set(value, forKey: property)
        UserDefaults.standard.synchronize()
    }
    
    func configurationForCurrentSegment(completion:((_ configuration:Configuration?)->())?) {
        LiveUpdateManager.sharedInstance.obtainConfiguration(self.currentSegment, useCache: false) { (configuration, error) in
            completion?(configuration)
        }
    }
}
