//
//  App-Header.h
//  J.A.R.B.A.S.
//
//  Created by Rafael Moris on 25/07/17.
//  Copyright © 2017 Marco Aurélio Bigélli Cardoso. All rights reserved.
//

//MARK: ### CONSTANTS ###

#define kNumberOfAvailableBackground 0
#define kImageBackgroundPrefix @"background_"

//MARK: ### IDENTIFIERS ###
#define kIDSettingsSegue @"SettingsSegue"
#define kIDConversationSegue @"ConversationSegue"
#define kIDTextToSpeechSegue @"TextToSpeechSegue"

//MARK: ### URLS ###

#define kURLUserConversation @"adapters/JarbasAdapter/resource/userConversation/"
#define kURLJarbasConversation @"adapters/JarbasAdapter/resource/jarbasConversation/"
#define kURLConversationAdapter @"adapters/ConversationAdapter/resource/conversation/"

//MARK: ### CONVERSATION ###

//MARK: ### ACTIONS ###

#define kActionCallJarbas @"callJarbas"
#define kActionEnableText @"enableo Texto"
#define kActionEnableVoice @"enablea Voz"
#define kActionEnableImage @"enableo reconhecimento de imagem"
#define kActionEnableSettings @"enableo botão de configurações"
#define kActionDisableText @"disableo Texto"
#define kActionDisableVoice @"disablea Voz"
#define kActionDisableImage @"disableo reconhecimento de imagem"
#define kActionDisableSettings @"disableo botão de configurações"
#define kActionShowConversation @"showConversation"
#define kActionShowTextToSpeech @"showText to speech"
#define kActionChooseRandomBackground @"chooseRandomBackground"
#define kActionChooseRandomColors @"chooseRandomColors"
#define kActionShowSettings @"showConfigurações"
#define kActionRunEasterEgg1 @"runEasteregg"
#define kActionRunEasterEgg2 @"runEasteregg2"
#define kStringEasterEgg1 @"easteregg_1"
#define kStringEasterEgg2 @"easteregg_2"

//MARK: ### LIVE UPDATE ###
#define kLiveUpdateWasModified @"was_live_update_modified"
#define kLiveUpdateInitialBackground @"background_4"
#define kLiveUpdateCurrentBackground @"current_background"
#define kLiveUpdateSettingsIsHidden @"settings_is_hidden"

//MARK: ### SEGMENTS ###

#define kInitialSegment @"voice_visual"
#define kSegmentHaveEverything @"have_everything"
#define kSegmentVoiceText @"voice_text"
#define kSegmentVoiceVisual @"voice_visual"
#define kSegmentVoiceOnly @"voice_only"
#define kSegmentTextVisual @"text_visual"
#define kSegmentTextOnly @"text_only"

//MARK: ### FEATURES ###

#define kFeatureTextMessage @"text_message"
#define kFeatureVoiceMessage @"voice_message"
#define kFeatureVisualRecognition @"visual_recognition"
#define kFeatureMapView @"map_view"
#define kFeatureStartConversation @"start_conversation"

//MARK: ### PROPERTIES ###

#define kPropertyStartConversationText @"start_conversation_text"
#define kPropertyMinimumDistance @"minimum_distance"
