//
// Copyright (C) 2005-2020 Alfresco Software Limited.
//
// This file is part of the Alfresco Content Mobile iOS App.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

protocol SplashScreenDelegate: class {
    func showAdvancedSettingsScreen()
    func showBackPadButton(enable: Bool)
}

class SplashViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var whiteAlphaView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var blurEfectView: UIVisualEffectView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var copyrightLabel: UILabel!

    weak var coordinatorDelegate: SplashScreenCoordinatorDelegate?
    weak var navigationControllerFromContainer: UINavigationController?

    var applyShadow: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        whiteAlphaView.applyCornerRadius(with: 10)
        containerView.applyCornerRadius(with: 10)
        blurEfectView.applyCornerRadius(with: 10)

        coordinatorDelegate?.showLoginContainerView()

        addMaterialComponentsTheme()
        addLocalization()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.backButton.isHidden = true
        if applyShadow {
            shadowView.dropContourShadow(opacity: 0.4, radius: 50)
            applyShadow = false
        }
    }

    // MARK: - IBActions

    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.coordinatorDelegate?.popViewControllerFromContainer()
    }

    // MARK: - Helpers

    func addLocalization() {
        copyrightLabel.text = String(format: LocalizationConstants.copyright, Calendar.current.component(.year, from: Date()))
    }

    func addMaterialComponentsTheme() {
        let theme = MaterialDesignThemingService()
        theme.activeTheme = DefaultTheme()

        copyrightLabel.textColor = theme.activeTheme?.loginCopyrightLabelColor
        copyrightLabel.font = theme.activeTheme?.loginCopyrightLabelFont

        backButton.tintColor = theme.activeTheme?.loginButtonColor
    }
}

extension SplashViewController: SplashScreenDelegate {

    func showBackPadButton(enable: Bool) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            backButton.isHidden = !enable
        } else {
            backButton.isHidden = true
        }
    }

    func showAdvancedSettingsScreen() {
        coordinatorDelegate?.showAdvancedSettingsScreen()
    }
}

extension SplashViewController: StoryboardInstantiable { }
