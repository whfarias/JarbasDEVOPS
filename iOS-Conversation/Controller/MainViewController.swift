//
//  MainViewController.swift
//  PinacoApp
//
//  Created by Gustavo Vicentini on 12/5/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import IBMMobileFirstPlatformFoundation
import IBMMobileFirstPlatformFoundationLiveUpdate
import Alamofire
import SwiftyJSON
import MapKit
import AVFoundation

private var myContext = 0
//preload gifs

extension UINavigationController {
//    override open var shouldAutorotate: Bool {
//        return false
//    }
//    
//    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
//        return .portrait
//    }
}

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var mapView:MKMapView!
    @IBOutlet weak var tableView: MessagesTableView!
    @IBOutlet weak var imgBackground: UIImageView!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var btnSpeech: UIButton!
    @IBOutlet weak var btnGallery: UIButton!
    @IBOutlet weak var btnCamera: UIButton!
    
    @IBOutlet weak var activityGallery: UIActivityIndicatorView!
    @IBOutlet weak var activityCamera: UIActivityIndicatorView!
    
    @IBOutlet weak var viewTextPaddingLeft: UIView!
    @IBOutlet weak var btnTextMessage: UIButton!
    @IBOutlet weak var btnSpeechMessage: UIButton!
    
    @IBOutlet weak var txtMessage: UITextField!
    
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnSpeechMessageWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var txtMessageHeightLayoutConstraint: NSLayoutConstraint!
    
    var locationManager = CLLocationManager()
    var usuario:Usuario?
    var produto:Produto?
    var lojaSelecionada:Loja?
    var annotations = [MKAnnotation]()
    
    var watson: Watson?
    
    var imagePicker:UIImagePickerController?
    var visualRecognition:VisualRecognition?
    var languageTranslator:LanguageTranslator?
    
    var distanciaMinima = 1.0
    var timestamp:TimeInterval?
    
    var avPlayer:AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Settings.loadFromDisk()
        
        self.imgBackground.frame = UIScreen.main.bounds
        self.txtMessage.delegate = self
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if let _ = Settings.accessToken {
            if Layout.shared.refreshLayout {
                Layout.shared.refreshLayout = false

                self.tableView.removeAll()
                
                LiveUpdate.shared.configurationForCurrentSegment(completion: { (configuration) in
                    self.customStartWithConfiguration(configuration)
                })
                
                WLAnalytics.sharedInstance().send();
            }
        }else {
            Layout.shared.refreshLayout = false
            
            self.watson = Watson()
            self.watson?.delegate = self
            
            let _ = WLClient.sharedInstance().serverUrl()
            
            WLAuthorizationManager.sharedInstance().obtainAccessToken(forScope: "RegisteredClient") { (token, error) in
                
                if let error = error {
                    print("Não foi recebido um Token do servidor: " + error.localizedDescription)
                    self.btnSettings.isHidden = false
                }else {
                    Settings.accessToken = token
                    
                    WLAnalytics.sharedInstance().addDeviceEventListener(LIFECYCLE);
                    WLAnalytics.sharedInstance().addDeviceEventListener(NETWORK);
                    
                    LiveUpdate.shared.configurationForCurrentSegment(completion: { (configuration) in
                        self.customStartWithConfiguration(configuration)
                    })
                }
            }
        }
        
//        WLAuthorizationManager.sharedInstance().obtainAccessToken(forScope: "mfp.admin.plugins") { (token, error) in
//            
//            
//            if let error = error {
//                print("Não foi recebido um Token do servidor: " + error.localizedDescription)
//                //                      self.delegate?.onClassificationError(errorDescription: error.localizedDescription)
//            }else {
//                print("TOKEN ADMIN: ", token)
//                //                    self.startClassifyWithText(text)
//            }
//        }
    }
    
    //MARK: ### LIVE UPDATE ###
    func refreshLiveUpdateConfiguration() {
        LiveUpdate.shared.configurationForCurrentSegment(completion: { (configuration) in
            self.refreshLayoutWithConfiguration(configuration)
        })
    }
    
    func customStartWithConfiguration(_ configuration:Configuration?) {
        var startMessage = ""
        var mapViewEnabled = false
        self.watson?.languageClassifier.lastContext.removeAll()
        
        self.btnSettings.isHidden = LiveUpdate.shared.settingsIsHidden
        
        if let configuration = configuration {
            if let enabled = configuration.isFeatureEnabled(kFeatureStartConversation), enabled {
                if let text = configuration.getProperty(kPropertyStartConversationText) {
                    startMessage = text
                }
            }
            
            if let distanciaMinima = configuration.getProperty(kPropertyMinimumDistance) {
                self.distanciaMinima = Double(distanciaMinima)!
            }
            
            if let enabled = configuration.isFeatureEnabled(kFeatureMapView), enabled {
                mapViewEnabled = true
            }
            
            self.updateLayoutWithConfiguration(configuration)
        }
        
        if Settings.orchestratorUsername != "" && Settings.voiceSynthesisUsername != "" {
            if startMessage.isEmpty && mapViewEnabled {
                self.buscarLojas(coordenada: self.usuario?.coordinate, verificarLoja: true)
            }else if mapViewEnabled {
                self.buscarLojas(coordenada: self.usuario?.coordinate, verificarLoja: false)
                self.watson?.mockQuestion(startMessage)
            }else {
                self.watson?.mockQuestion(startMessage)
            }
        }
        
        self.renderLayout()
    }
    
    func refreshLayoutWithConfiguration(_ configuration:Configuration?) {
        if let configuration = configuration {
            if let distanciaMinima = configuration.getProperty(kPropertyMinimumDistance) {
                self.distanciaMinima = Double(distanciaMinima)!
            }
            
            self.updateLayoutWithConfiguration(configuration)
        }
        
        self.renderLayout()
    }
    
    func updateLayoutWithConfiguration(_ configuration:Configuration) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        var voice = false
        if let enabled = configuration.isFeatureEnabled(kFeatureVoiceMessage), enabled {
            voice = true
        }
        
        var text = false
        if let enabled = configuration.isFeatureEnabled(kFeatureTextMessage), enabled {
            text = true
        }
        
        var visualRecognition = false
        if let enabled = configuration.isFeatureEnabled(kFeatureVisualRecognition), enabled {
            visualRecognition = true
        }
        
        var mapViewEnabled = false
        if let enabled = configuration.isFeatureEnabled(kFeatureMapView), enabled {
            mapViewEnabled = true
        }
        
        self.watson?.isVoiceEnabled = voice
        self.watson?.isTextEnabled = text
        
        if voice && !text {
            self.btnSpeech.isHidden = false
            self.btnTextMessage.isHidden = true
            self.viewTextPaddingLeft.isHidden = true
            self.btnSpeechMessage.isHidden = true
            self.btnSpeechMessageWidthLayoutConstraint.constant = 0
            self.txtMessage.isHidden = true
            self.txtMessageHeightLayoutConstraint.constant = 0
            self.tableView.isHidden = true
            self.txtMessage.resignFirstResponder()
        }else if !voice && text {
            self.btnSpeech.isHidden = true
            self.btnTextMessage.isHidden = false
            self.viewTextPaddingLeft.isHidden = false
            self.btnSpeechMessage.isHidden = true
            self.btnSpeechMessageWidthLayoutConstraint.constant = 0
            self.txtMessage.isHidden = false
            self.txtMessageHeightLayoutConstraint.constant = 40
            self.tableView.isHidden = false
            self.txtMessage.becomeFirstResponder()
        }else if voice && text {
            self.btnSpeech.isHidden = true
            self.btnTextMessage.isHidden = false
            self.viewTextPaddingLeft.isHidden = false
            self.btnSpeechMessage.isHidden = false
            self.btnSpeechMessageWidthLayoutConstraint.constant = 40
            self.txtMessage.isHidden = false
            self.txtMessageHeightLayoutConstraint.constant = 40
            self.tableView.isHidden = false
            self.txtMessage.becomeFirstResponder()
        }else {
            self.btnSpeech.isHidden = true
            self.btnTextMessage.isHidden = true
            self.viewTextPaddingLeft.isHidden = true
            self.btnSpeechMessage.isHidden = true
            self.btnSpeechMessageWidthLayoutConstraint.constant = 0
            self.txtMessage.isHidden = true
            self.txtMessageHeightLayoutConstraint.constant = 0
            self.tableView.isHidden = true
            self.txtMessage.resignFirstResponder()
        }
        
        if visualRecognition {
            self.btnGallery.isHidden = false
            self.btnCamera.isHidden = false
        }else {
            self.btnGallery.isHidden = true
            self.btnCamera.isHidden = true
        }
        
        if mapViewEnabled {
            self.mapView.isHidden = false
            self.initMapView()
        }else {
            self.mapView.isHidden = true
        }
    }
    
    @IBAction func startListening(_ sender: AnyObject) {
        var scale:CGFloat = 1.0
        if watson?.state == .idle {
            scale = 1.5
            
            self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_listening"), for: .normal)
            self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_listening"), for: .normal)

            self.timestamp = Date.timeIntervalSinceReferenceDate
            watson?.startListening()
            
            let metadata = ["Event": "Voice Interaction"];
            WLAnalytics.sharedInstance().log("Search Event", withMetadata: metadata)
            WLAnalytics.sharedInstance().send();
            
        } else {
            self.timestamp = nil
            watson?.stop()
        }
        
        self.animarTamanho(view: self.btnSpeech, scale: scale)
    }
    
    @IBAction func forceStopListening(_ sender: AnyObject) {
        self.timestamp = nil
        self.watson?.stop()
        let scale:CGFloat = 1.0
        self.animarTamanho(view: self.btnSpeech, scale: scale)
    }
    
    @IBAction func stopListening(_ sender: AnyObject) {
        self.animarTamanho(view: self.btnSpeech, scale: 1.0)
        
        if let timestamp = self.timestamp, Date.timeIntervalSinceReferenceDate - timestamp >= 1 {
            
            delay(1.0) {
                    self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_idle"), for: .normal)
                    self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_idle"), for: .normal)
                    
                    (self.watson?.speechRecognizer as? NativeSpeechRecognizer)?.finishRecording()
            }
            
        }else {
            self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_idle"), for: .normal)
            self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_idle"), for: .normal)
            watson?.stop()
        }
    }
    
    func animarTamanho(view:UIView, scale:CGFloat) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(0.25)
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
        UIView.commitAnimations()
    }
    
    //MARK: ### Map View ###
    func initMapView() {
        self.mapView.delegate = self
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.distanceFilter = 500
        self.locationManager.startUpdatingLocation()
        self.locationManager.startMonitoringSignificantLocationChanges()
        
        self.locationManager.delegate = self
        
        self.verificarAutorizacaoLocalizacao()
    }
    
    func alterarStatusVisualRecognition(running:Bool) {
        if running {
            self.btnCamera.setImage(nil, for: .normal)
            self.btnCamera.isEnabled = false
            self.activityCamera.startAnimating()
            self.activityCamera.isHidden = false
            
            self.btnGallery.setImage(nil, for: .normal)
            self.btnCamera.isEnabled = false
            self.activityGallery.startAnimating()
            self.activityGallery.isHidden = false
        }else {
            self.btnGallery.setImage(#imageLiteral(resourceName: "btn_gallery"), for: .normal)
            self.btnGallery.isEnabled = true
            self.activityGallery.stopAnimating()
            self.activityGallery.isHidden = true
            
            self.btnCamera.setImage(#imageLiteral(resourceName: "btn_camera"), for: .normal)
            self.btnCamera.isEnabled = true
            self.activityCamera.stopAnimating()
            self.activityCamera.isHidden = true
        }
    }
    
    @IBAction func showCamera(_ sender: AnyObject) {
        if watson?.state != .idle {
            watson?.stop()
        }
        self.takePhoto()
    }
    
    @IBAction func showGallery(_ sender: AnyObject) {
        if watson?.state != .idle {
            watson?.stop()
        }
        self.selectPhoto()
    }
    
    //MARK: ### CONVERSATION ###
    @IBAction func textButtonTapped(_ sender: AnyObject) {
        self.sendTextMessage()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendTextMessage()
        return true
    }
    
    func sendTextMessage() {
        if let text = self.txtMessage.text, !text.isEmpty {
            if let watson = self.watson {
                self.txtMessage.text = nil
                watson.mockQuestion(text)
            }
        }
    }
    
    func normalizeTextChat(_ text:String)-> String {
        var output = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        output =
            output.replacingOccurrences(of: "\\s?[-][=](.*?)[=][-]", with: "", options: .regularExpression, range: nil)
        
        output = output.replacingOccurrences(of: "+=", with: "")
        output = output.replacingOccurrences(of: "=+", with: "")
        
        return output
    }
    
    func showUserMessage(text:String) {
        if !text.isEmpty {
            if self.tableView.messages.count >= 1 {
                let message = Message(source: .user, text: self.normalizeTextChat(text))
                self.tableView.append(message: message)
                
                let metadata = ["Event": "Text Interaction"];
                WLAnalytics.sharedInstance().log("Search Event", withMetadata: metadata)
                WLAnalytics.sharedInstance().send();
            }
        }
    }
    
    func resolveConversationAction(_ action: String) {
        switch action {
        case kActionEnableText:
            LiveUpdate.shared.setValue(true, forFeatureKey: kFeatureTextMessage)
            self.refreshLiveUpdateConfiguration()
            
        case kActionEnableVoice:
            LiveUpdate.shared.setValue(true, forFeatureKey: kFeatureVoiceMessage)
            self.refreshLiveUpdateConfiguration()
            
        case kActionEnableImage:
            LiveUpdate.shared.setValue(true, forFeatureKey: kFeatureVisualRecognition)
            self.refreshLiveUpdateConfiguration()
            
        case kActionEnableSettings:
            LiveUpdate.shared.settingsIsHidden = true
            self.btnSettings.isHidden = false
            
        case kActionDisableText:
            LiveUpdate.shared.setValue(false, forFeatureKey: kFeatureTextMessage)
            self.refreshLiveUpdateConfiguration()
            
        case kActionDisableVoice:
            LiveUpdate.shared.setValue(false, forFeatureKey: kFeatureVoiceMessage)
            self.refreshLiveUpdateConfiguration()
            
        case kActionDisableImage:
            LiveUpdate.shared.setValue(false, forFeatureKey: kFeatureVisualRecognition)
            self.refreshLiveUpdateConfiguration()
            
        case kActionDisableSettings:
            LiveUpdate.shared.settingsIsHidden = true
            self.btnSettings.isHidden = true
            
        case kActionShowConversation:
            Settings.segueValue = kIDConversationSegue
            self.performSegue(withIdentifier: kIDSettingsSegue, sender: kActionShowConversation)
            
        case kActionShowTextToSpeech:
            Settings.segueValue = kIDTextToSpeechSegue
            self.performSegue(withIdentifier: kIDSettingsSegue, sender: nil)
            
        case kActionShowSettings:
            self.performSegue(withIdentifier: kIDSettingsSegue, sender: nil)
            
        case kActionChooseRandomBackground:
            LiveUpdate.shared.setValue("\(kImageBackgroundPrefix)\((Math.random(min: 0, max: Int(kNumberOfAvailableBackground))))", forPropertyKey: kLiveUpdateCurrentBackground)
            self.refreshLiveUpdateConfiguration()
            
        case kActionChooseRandomColors:
            Layout.shared.chooseRandomColors = true
            self.refreshLiveUpdateConfiguration()
            
        case kActionRunEasterEgg1:
            self.playEasterEgg(name: kStringEasterEgg1)
        case kActionRunEasterEgg2:
            self.playEasterEgg(name: kStringEasterEgg2)
            
        default:
            break
        }
    }
    
    func callJarbas(text: String, visualRecognition:Bool) {
        print("Call Jarbas:", text)
        self.timestamp = nil
        self.watson?.stop()
        self.watson?.mockQuestion(text, callJarbas: true, visualRecognition: visualRecognition)
    }
    
    func playEasterEgg(name:String) {
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            
            do {
                self.avPlayer = try AVAudioPlayer(contentsOf: url)
                guard let avPlayer = self.avPlayer else {
                    return
                }
                
                avPlayer.prepareToPlay()
                avPlayer.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func showWatsonMessage(text:String) {
        if !text.isEmpty {
            let message = Message(source: .watson, text: self.normalizeTextChat(text))
            self.tableView.append(message: message)
        }
    }
    
    func renderLayout() {
        let layout = Layout.shared
        
        UINavigationBar.appearance().tintColor = layout.colorForString(layout.globalTintColor)
        
        self.imgBackground.image = UIImage(named: LiveUpdate.shared.currentBackground)
        
        self.btnSpeech.tintColor = layout.colorForString(layout.btnSpeechTintColor)
        self.btnSpeech.backgroundColor = layout.colorForString(layout.btnSpeechBackgroundColor, withAlpha: 0.8)
        
        self.btnSpeech.layer.cornerRadius = self.btnSpeech.frame.height / 2
        self.btnSpeech.layer.masksToBounds = true
        self.btnSpeech.contentMode = .scaleAspectFill
        
        self.btnGallery.tintColor = layout.colorForString(layout.btnGalleryTintColor)
        self.btnGallery.backgroundColor = layout.colorForString(layout.btnGalleryBackgroundColor, withAlpha: 0.8)
        
        self.btnGallery.layer.cornerRadius = self.btnGallery.frame.height / 2
        self.btnGallery.layer.masksToBounds = true
        self.btnGallery.contentMode = .scaleAspectFill
        
        self.btnCamera.tintColor = layout.colorForString(layout.btnCameraTintColor)
        self.btnCamera.backgroundColor = layout.colorForString(layout.btnCameraBackgroundColor, withAlpha: 0.8)
        
        self.btnCamera.layer.cornerRadius = self.btnCamera.frame.height / 2
        self.btnCamera.layer.masksToBounds = true
        self.btnCamera.contentMode = .scaleAspectFill
        
        self.btnSettings.tintColor = layout.colorForString(layout.btnSettingsTintColor)
        self.btnSettings.backgroundColor = layout.colorForString(layout.btnSettingsBackgroundColor, withAlpha: 0.8)
        
        self.btnSettings.layer.cornerRadius = self.btnSettings.frame.height / 2
        self.btnSettings.layer.masksToBounds = true
        self.btnSettings.contentMode = UIViewContentMode.scaleAspectFill
        
        self.btnTextMessage.tintColor = layout.colorForString(layout.btnTextMessageTintColor)
        self.btnTextMessage.backgroundColor = layout.colorForString(layout.btnTextMessageBackgroundColor, withAlpha: 0.8)
        
        self.btnSpeechMessage.tintColor = layout.colorForString(layout.btnSpeechMessageTintColor)
        self.btnSpeechMessage.backgroundColor = layout.colorForString(layout.btnSpeechMessageBackgroundColor, withAlpha: 0.8)
        
        self.txtMessage.textColor = layout.colorForString(layout.txtMessageTextColor)
        self.txtMessage.backgroundColor = layout.colorForString(layout.txtMessageBackgroundColor, withAlpha: 0.8)
        self.viewTextPaddingLeft.backgroundColor = self.txtMessage.backgroundColor
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
                let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
                let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
                let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
                if endFrame.origin.y >= UIScreen.main.bounds.size.height {
                    self.keyboardHeightLayoutConstraint?.constant = 0.0
                } else {
                    self.keyboardHeightLayoutConstraint?.constant = endFrame.size.height
                }
                UIView.animate(withDuration: duration, delay: TimeInterval(0), options: animationCurve, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
}

// MARK: - Location Manager
extension MainViewController:CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.currentUserLocation(location: location)
        }
    }
}

// MARK: - MapView
extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView:MKAnnotationView!
        if let usuario = self.usuario, annotation.isEqual(usuario) {
            let pinId = "walmart.usuario"
            pinView = mapView.dequeueReusableAnnotationView(withIdentifier: pinId)
            if pinView == nil {
                pinView = MKAnnotationView(annotation: self.usuario, reuseIdentifier: pinId)
            }
            
            pinView?.image = #imageLiteral(resourceName: "pin_usuario")
        }else if let _ = annotation as? Loja {
            let pinId = "walmart.loja"
            pinView = mapView.dequeueReusableAnnotationView(withIdentifier: pinId)
            if pinView == nil {
                pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: pinId)
            }
            
            pinView?.image = #imageLiteral(resourceName: "pin_walmart")
            
            for view in pinView.subviews {
                view.removeFromSuperview()
            }
            
            if let produto = self.produto {
                if let view = UIView.loadFromNibNamed("ProdutoMapaView") as? ProdutoMapaView {
                    view.imageView.image = produto.image
                    view.lblTitle.text = produto.title
                    view.lblPrice.text = produto.price == nil ? nil : "R$ \(produto.price!)"
                    view.frame.origin.x = abs(view.frame.width - pinView.frame.width) * -0.5
                    view.frame.origin.y = -(view.frame.height + 8)
                    pinView.addSubview(view)
                }
            }
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? Loja {
            if let title = annotation.title {
                self.watson?.speak(title)
            }
        
            if !annotation.isEqual(self.lojaSelecionada) {
                self.lojaSelecionada = annotation
                self.refreshAnnotations(readicionarAnotacoes: false)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(hexString: "#73b9ff")
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    func centralizarMapa(local:CLLocation) {
        let regiao:CLLocationDistance = 1000
        self.centralizarMapa(local: local, regiao: regiao)
    }

    func centralizarMapa(local:CLLocation, regiao:CLLocationDistance) {
        let coordenada = MKCoordinateRegionMakeWithDistance(local.coordinate, regiao * 2.0, regiao * 2.0)
        
        self.mapView.setRegion(coordenada, animated: true)
    }
    
    func currentUserLocation(location:CLLocation) {
        if self.usuario == nil {
            self.usuario = Usuario(title: "Usuário", locationName: "Localização atual", discipline: "Usuário", coordinate: location.coordinate)
        }else {
            self.usuario?.coordinate = location.coordinate
        }
    }
    
    func buscarOfertas() {
        if let coordenada = self.usuario?.coordinate {
            if var context = self.watson?.languageClassifier.lastContext {
                if let entities = self.watson?.languageClassifier.lastEntities {
                    
                    if (context["action"] as? String) == nil {
                        return
                    }
                    
                    if let action = context["action"] as? String, action == "not found" {
                        return
                    }
                    
                    context["timezone"] = "America/Sao_Paulo"
                    
                    let offersURL = "adapters/GetNearStoresAdapter/resource/getnearstoreofferlat"
                    
                    let request = WLResourceRequest(url: URL(string: offersURL), method: WLHttpMethodPost)
                    
                    request?.setHeaderValue("application/json" as NSObject, forName: "Content-Type")
                    
                    let jsonContext = JSON(context)
                    let jsonEntities = JSON(entities)
                    
                    var body = "{"
                    body += "\"location\": {"
                    body += "\"longitude\": \(coordenada.longitude),"
                    body += "\"latitude\": \(coordenada.latitude),"
                    body += "\"radius\": 20000"
                    body += "},"
                    body += "\"conversation_data\": {"
                    
                    body += "\"entities\" :"
                    
                    
                    if let entities = jsonEntities.rawString() {
                        body += entities
                    }else {
                        body += "[]"
                    }
                    
                    body += ",\"context\" :"
                    if let action = jsonContext["action"].string {
                        body += "{"
                            body += "\"action\" : \"\(action)\""
                        body += "}"
                    }else {
                        body += "{}"
                    }
                    
                    body += "}"
                    body += "}"
                    
                    request?.send(withBody: body, completionHandler: { (response, error) in
                        if let error = error {
                            print("Failure: " + error.localizedDescription)
                        }else {
                            if let response = response {
                                let json = JSON(response.responseData)
                                
                                self.verificarResultado(json: json)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func verificarResultado(json:SwiftyJSON.JSON) {
        if let stores = json["stores"].array {
            self.mostrarLojas(lojas: stores)
        }
        
        if let store = json["stores"].array?.first {
            if let _ = self.watson?.languageClassifier.lastContext {
                if let local = store["name"].string {
                    if let promotion = store["promotions"].array?.first {
                        var preco:String?
                        if let promotionalPrice = promotion["extraField"]["promotionalPrice"].string {
                         
                            preco = promotionalPrice
                        }else if let price = promotion["extraField"]["price"].string {
                            
                            preco = price
                        }
                        
                        if let preco = preco {
                            
                            self.watson?.languageClassifier.lastContext["local"] = local
                            self.watson?.languageClassifier.lastContext["price"] = " \(preco)"
                            
                            if let productName = promotion["name"].string {
                                let metadata = ["Success Search": "\(productName) (R$\(preco)) - \(local)"];
                                WLAnalytics.sharedInstance().log("Success Search", withMetadata: metadata)
                                WLAnalytics.sharedInstance().send();
                                
                                if let url = promotion["images"].array?.first?.string {
                                    
                                    let request = WLResourceRequest(url: URL(string: url), method: WLHttpMethodGet)
                                    
                                    request?.send(completionHandler: { (response, error) in
                                        if let data = response?.responseData {
                                            self.produto = Produto(title: productName, locationName: productName, discipline: "Produto", coordinate: CLLocationCoordinate2D(), price: preco)
                                            
                                            self.produto?.image = UIImage(data: data, scale: 7.0)
                                            self.refreshAnnotations(readicionarAnotacoes: true)
                                        }
                                    })
                                }
                            }
                            self.watson?.mockQuestion("")
                        }
                    }
                }
            }
        }else {
            self.watson?.languageClassifier.lastContext["local"] = nil
            self.watson?.languageClassifier.lastContext["price"] = nil
            self.watson?.mockQuestion("")
        }
    }
    
    
    func buscarLojas(coordenada:CLLocationCoordinate2D?, verificarLoja:Bool) {
        if let coordenada = coordenada {
            
            if var context = self.watson?.languageClassifier.lastContext {
                context["timezone"] = "America/Sao_Paulo"
                
                let storesURL = "adapters/GetNearStoresAdapter/resource/getnearstores"
                
                let request = WLResourceRequest(url: URL(string: storesURL), method: WLHttpMethodPost)
                
                request?.setHeaderValue("application/json" as NSObject, forName: "Content-Type")
                
                var body = "{"
                    body += "\"location\": {"
                        body += "\"longitude\": \(coordenada.longitude),"
                        body += "\"latitude\": \(coordenada.latitude),"
                        body += "\"radius\": 20000"
                    body += "}"
                body += "}"
                
                request?.send(withBody: body, completionHandler: { (response, error) in
                    //            request?.send(withJSON: requestParams, completionHandler: { (response, error) in
                    if let error = error {
                        print("Failure: " + error.localizedDescription)
                    }else {
                        if let response = response {
                            let json = JSON(response.responseData)
                            
                            if let latitude = json["stores"].array?.first?["location"]["latitude"].string {
                                if let longitude = json["stores"].array?.first?["location"]["longitude"].string {
                                    
                                    let location = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                                    
                                    if let title = json["stores"].array?.first?["name"].string {
                                        let locationName = json["stores"].array?.first?["neighborhood"].string
                                        
                                        var discipline = "Hipermercado"
                                        
                                        if let storeType = json["stores"].array?.first?["storeType"].string {
                                            discipline = storeType
                                        }
                                        
                                        let loja = Loja(title: title, locationName: locationName!, discipline: discipline, coordinate: location.coordinate)
                                        
                                        if verificarLoja {
                                            self.watson?.languageClassifier.lastContext.removeAll()
                                            self.watson?.languageClassifier.lastEntities.removeAll()
                                            
                                            if let distancia = json["stores"].array?.first?["distance"].double, distancia <= self.distanciaMinima {
                                                
                                                let messagem = title
                                                self.watson?.mockQuestion(messagem)
                                            }else {
                                                self.watson?.mockQuestion("")
                                            }
                                        }
                                        
                                        self.mostrarLoja(loja: loja)
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    func mostrarLoja(loja:Loja) {
        self.annotations.removeAll()
        self.lojaSelecionada = loja
        self.annotations.append(loja)
        self.refreshAnnotations(readicionarAnotacoes: true)
    }
    
    func mostrarLojas(lojas:[SwiftyJSON.JSON]) {
        self.annotations.removeAll()
        
        for jsonLoja in lojas {
            if let latitude = jsonLoja["location"]["latitude"].string {
                if let longitude = jsonLoja["location"]["longitude"].string {
                    
                    let location = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                    
                    let title = jsonLoja["name"].string!
                    let locationName = jsonLoja["neighborhood"].string
                    
                    var discipline = "Hipermercado"
                    if let storeType = jsonLoja["storeType"].string {
                        discipline = storeType
                    }
                    
                    let loja = Loja(title: title, locationName: locationName!, discipline: discipline, coordinate: location.coordinate)
                    
                    self.annotations.append(loja)
                }
            }
        }
        self.lojaSelecionada = self.annotations.first as? Loja
        self.refreshAnnotations(readicionarAnotacoes: true)
    }
    
    func refreshAnnotations(readicionarAnotacoes:Bool) {
        if let lojaMaisProxima = self.lojaSelecionada {
            self.annotations.insert(self.usuario!, at: 0)
            
            if readicionarAnotacoes {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.showAnnotations(self.annotations, animated: true)
            }
            
            let sourcePlacemark = MKPlacemark(coordinate: self.usuario!.coordinate, addressDictionary: nil)
            let destinationPlacemark = MKPlacemark(coordinate: lojaMaisProxima.coordinate, addressDictionary: nil)
            
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            let directionRequest = MKDirectionsRequest()
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            directionRequest.transportType = .automobile
            
            // Calculate the direction
            let directions = MKDirections(request: directionRequest)
            
            // 8.
            directions.calculate {
                (response, error) -> Void in
                
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }
                
                self.mapView.removeOverlays(self.mapView.overlays)
                
                let route = response.routes[0]
                self.mapView.add(route.polyline, level: .aboveRoads)
                
                var rect = route.polyline.boundingMapRect
                rect.origin.x -= 1200
                rect.origin.y -= 1200
                rect.size.width += 2400
                rect.size.height += 2400
                self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
            }
        }
    }
    
    func verificarAutorizacaoLocalizacao() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
//            self.mapView.showsUserLocation = true
        }else {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK: - LanguageTranslator
extension MainViewController: LanguageTranslatorDelegate {
    func onTranslationStart() {
        
    }
    
    func onTranslationSuccess(result: SwiftyJSON.JSON) {
        if let text = result["translations"][0]["translation"].string {
            print("LanguageTranslator Synthesize: ", text)
            self.alterarStatusVisualRecognition(running: false)
            
//            if var context = self.watson?.languageClassifier.jarbasLastContext {
//                context["VR"] = text
            self.watson?.mockQuestion(text, visualRecognition:true)
//                self.watson?.speak(text)
//            }
        }
    }
    
    func onTranslationError(errorDescription: String) {
        
    }
}

// MARK: - VisualRecognition
extension MainViewController: VisualRecognitionDelegate {
    func onRecognitionStart() {
        
    }
    
    func onRecognitionSuccess(result: SwiftyJSON.JSON) {
        if let classifiers = result["images"][0]["classifiers"].array {
            
            var classValue:String?
            if let value = self.firstValueForClassifierName("food", classifiers: classifiers), value != "non-food" {
                
                classValue = value
            }else if let value = self.firstValueForClassifierName("default", classifiers: classifiers) {
                
                classValue = value
            }
            
            if let classValue = classValue {
                self.languageTranslator = LanguageTranslator()
                self.languageTranslator?.delegate = self
                self.languageTranslator?.translate(text: classValue)
            }
        }
    }
    
    func firstValueForClassifierName(_ name:String, classifiers:[SwiftyJSON.JSON])-> String? {
        
        for classifier in classifiers {
            if let nome = classifier["classifier_id"].string, nome == name {
                
                if let classValue = classifier["classes"].array?[0]["class"].string {
                    return classValue
                }
            }
        }
        return nil
    }
    
    func onRecognitionError(errorDescription: String) {
        
    }
}

// MARK: - UIImagePickerController
extension MainViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func takePhoto() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.sourceType = .camera
        self.imagePicker?.delegate = self
        self.present(self.imagePicker!, animated: true) {
        }
    }
    
    func selectPhoto() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.sourceType = .photoLibrary
        self.imagePicker?.delegate = self
        self.present(self.imagePicker!, animated: true) {
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        Layout.shared.refreshLayout = false
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.visualRecognition = VisualRecognition()
            self.visualRecognition?.delegate = self
            self.visualRecognition?.classify(image: image)
            
            self.alterarStatusVisualRecognition(running: true)
            
            let metadata = ["Event": "Visual Interaction"];
            WLAnalytics.sharedInstance().log("Search Event", withMetadata: metadata)
            WLAnalytics.sharedInstance().send();
        }else {
            self.alterarStatusVisualRecognition(running: false)
        }
        
        self.imagePicker?.dismiss(animated: true, completion: { 
            
        })
    }
}

// MARK: - WatsonDelegate
extension MainViewController: WatsonDelegate {
    func didChangeState(from: WatsonState, to: WatsonState) {
        DispatchQueue.main.async {
            switch to {
            case .idle:
                self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_idle"), for: .normal)
                self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_idle"), for: .normal)
            case .listening:
                self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_listening"), for: .normal)
                self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_listening"), for: .normal)
            case .classifying:
                self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_thinking"), for: .normal)
                self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_thinking"), for: .normal)
            case .synthesizing:
                self.buscarOfertas()
                self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_synthesizing"), for: .normal)
                self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_synthesizing"), for: .normal)
            case .speaking:
                self.btnSpeech?.setImage(#imageLiteral(resourceName: "btn_answering"), for: .normal)
                self.btnSpeechMessage?.setImage(#imageLiteral(resourceName: "btn_answering"), for: .normal)
            }
        }
    }
    
    func didFinishPrepareAudio() {
        
    }
    
    func didFail(module: String, description: String) {
//        UIHelper.simpleAlert(title: module + " error", text: description, owner: self)
    }
}
