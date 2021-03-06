//
//  WelcolmeViewController.swift
//  Music Room 3
//
//  Created by ML on 24/11/2020.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import FBSDKCoreKit

class WelcolmeViewController: UIViewController {
    
    // TEST SPOTIFY
//    var alwaysOnView: TestViewController!
    @IBOutlet var TestViewController: TestViewController!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let loggued: Bool = UserDefaults.standard.bool(forKey: "logued")
        
        // Let's say no user is connected right now
        //loggued = false
        if loggued == true {
            performSegue(withIdentifier: "logSegue1", sender: self)
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "FacebookLoggued")
        UserDefaults.standard.setValue(false, forKey: "logued")
        UserDefaults.standard.setValue(false, forKey: "Googlelogued")
        UserDefaults.standard.setValue(false, forKey: "MailLogued")
    
        // Check if there if a Facebook User has previously loggued in !
        if let token = AccessToken.current, !token.isExpired {
            // Surement pas la bonne manière 
            print("on a un token facebook")
            UserDefaults.standard.setValue(true, forKey: "FacebookLoggued")
            UserDefaults.standard.setValue(true, forKey: "logued")
        }
        
        // Check if there if a Google User has previously loggued in !
        if let _ = GIDSignIn.sharedInstance()?.currentUser {
            UserDefaults.standard.setValue(true, forKey: "Googlelogued")
            UserDefaults.standard.setValue(true, forKey: "logued")
        }
        
        var loggued: Bool = UserDefaults.standard.bool(forKey: "logued")
      
        // Let's say no user is connected right now
        loggued = false
        
        if loggued == true {
            //print("Logued = ", loggued)
            performSegue(withIdentifier: "logSegue1", sender: self)
        }
    }
    
    @IBAction func existingAccount(_ sender: Any) {
        performSegue(withIdentifier: "logSegue1", sender: self)
    }
    
    @IBAction func unwindToLogPage(segue:UIStoryboardSegue) { }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logSegue1" {
            _ = segue.destination as! ConnectionViewController
        }
    }
    
    
    // SPOTIFY TEST
    private let SpotifyClientID = "39c09e90077544a7a6d71a0fbf058a25"
    private let SpotifyRedirectURI = URL(string: "musicroomsdkspotify://login")!

    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: SpotifyClientID, redirectURL: SpotifyRedirectURI)
        // Set the playURI to a non-nil value so that Spotify plays music after authenticating and App Remote can connect
        // otherwise another app switch will be required
        configuration.playURI = ""

        // Set these url's to your backend which contains the secret to exchange for an access token
        // You can use the provided ruby script spotify_token_swap.rb for testing purposes
        configuration.tokenSwapURL = URL(string: "http://62.34.5.191:45559/spotify/authorization_code/access_token")
        configuration.tokenRefreshURL = URL(string: "http://62.34.5.191:45559/spotify/authorization_code/refresh_token")
        print("config made")
        return configuration
    }()

    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()

    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()

    private var lastPlayerState: SPTAppRemotePlayerState?


    @IBAction func spotifyconnectbutton(_ sender: Any) {
        let scope: SPTScope = [.appRemoteControl, .playlistReadPrivate]

        if #available(iOS 11, *) {
            // Use this on iOS 11 and above to take advantage of SFAuthenticationSession
            sessionManager.initiateSession(with: scope, options: .clientOnly)
            print("session Manager . initiate Session")
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            sessionManager.initiateSession(with: scope, options: .clientOnly, presenting: self)
        }
    }
    
    @IBAction func pausebutton(_ sender: Any) {
        appRemote.connect()
        print("on appuie sur le bouton")
        print("appRemote.isConnected: ", appRemote.isConnected)
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
        } else {
            appRemote.playerAPI?.pause(nil)
        }
    }
    
    @IBAction func deconnectbutton(_ sender: Any) {
        if (appRemote.isConnected) {
            appRemote.disconnect()
        }
    }
}

extension WelcolmeViewController: SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    // SPOTIFY TEST
    
    
    
    
    
  
    
    
    func update(playerState: SPTAppRemotePlayerState) {
        if lastPlayerState?.track.uri != playerState.track.uri {
            fetchArtwork(for: playerState.track)
        }
        lastPlayerState = playerState
        if playerState.isPaused {
            //pauseAndPlayButton.setImage(UIImage(named: "play"), for: .normal)
        } else {
            //pauseAndPlayButton.setImage(UIImage(named: "pause"), for: .normal)
        }
    }

    func fetchArtwork(for track:SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                //print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                //self?.imageView.image = image
            }
        })
    }

    func fetchPlayerState() {
        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                //print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
    }
    
    // MARK: - SPTSessionManagerDelegate

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("did fail with error")
        presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("did renew")
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("did initiate session")
        appRemote.connectionParameters.accessToken = session.accessToken
        print("access token : ", appRemote.connectionParameters.accessToken)
        appRemote.connect()
        print("appRemote.isConnected: ", appRemote.isConnected)
        
    }

    // MARK: - SPTAppRemoteDelegate

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
        fetchPlayerState()
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        lastPlayerState = nil
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        lastPlayerState = nil
    }

    // MARK: - SPTAppRemotePlayerAPIDelegate

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        update(playerState: playerState)
    }

    // MARK: - Private Helpers

    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
}

