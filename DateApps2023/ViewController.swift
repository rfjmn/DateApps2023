//
//  ViewController.swift
//  DateApps2023
//
//  Created by 藤門莉生 on 2023/02/14.
//

import UIKit

/*
 # About Warning
 参考URL: https://zenn.dev/nekomimimi/scraps/c27eee05173a07
 */

final class ViewController: UIViewController {
    @IBOutlet private var signupButton: UIButton!
    @IBOutlet private var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureUI()
    }

    private func configureUI() {
        signupButton.layer.cornerRadius = 20
        loginButton.layer.cornerRadius = 20
    }

    @IBAction private func tapSignupButton(_: Any) {
        let storyboard = UIStoryboard(name: "Signup", bundle: nil)

        if let signupVC = storyboard.instantiateViewController(withIdentifier: "signup") as? SignupViewController {
            navigationController?.pushViewController(signupVC, animated: true)
        }
    }

    @IBAction private func tapLoginButton(_: Any) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)

        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "login") as? LoginViewController {
            navigationController?.pushViewController(loginViewController, animated: true)
        }
    }
}
