//
//  SettingsTableViewController.swift
//  Watson Conversation
//
//  Created by Marco Aurélio Bigélli Cardoso on 09/04/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation
import UIKit

class SettingsTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if Settings.segueValue == kIDConversationSegue {
            self.performSegue(withIdentifier: kIDConversationSegue, sender: nil)
        }else if Settings.segueValue == kIDTextToSpeechSegue {
            self.performSegue(withIdentifier: kIDTextToSpeechSegue, sender: nil)
        }
        Settings.segueValue = nil
    }
}
