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

struct DefaultTheme: PresentationTheme {

    // TYPOGRAPHY
    var headline3TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 48.0), lineHeight: 1.33, letterSpacing: 0.0)
    var headline4TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 34.0), lineHeight: 1.41, letterSpacing: 0.25)
    var headline5TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 24.0), lineHeight: 1.50, letterSpacing: 0.0)
    var headline6TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 20.0), lineHeight: 1.40, letterSpacing: 0.15)
    var subtitle1TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 16.0), lineHeight: 1.50, letterSpacing: 0.15)
    var subtitle2TextStyle = TextStyle(font: UIFont.inter(style: .medium, size: 14.0), lineHeight: 1.43, letterSpacing: 0.1)
    var buttonTextStyle = TextStyle(font: UIFont.inter(style: .medium, size: 14.0), lineHeight: 1.71, letterSpacing: 0.1)
    var body1TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 16.0), lineHeight: 1.50, letterSpacing: 0.444444)
    var body2TextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 14.0), lineHeight: 1.43, letterSpacing: 0.25)
    var captionTextStyle = TextStyle(font: UIFont.inter(style: .normal, size: 12.0), lineHeight: 1.33, letterSpacing: 0.5)
    var overlineTextStyle = TextStyle(font: UIFont.inter(style: .medium, size: 10.0), lineHeight: 1.60, letterSpacing: 0.2)
    var headLineBoldTextStyle = TextStyle(font: UIFont.inter(style: .bold, size: 14.0), lineHeight: 1.42, letterSpacing: 0.0)
    var toolBarTextStyle = TextStyle(font: UIFont.inter(style: .medium, size: 16.0), lineHeight: 1.43, letterSpacing: 0.1)

    // COLORS

    var surfaceColor = UIColor(hex: "#FFFFFF")
    var surface60Color = UIColor(hex: "#FFFFFF", alpha: 0.6)
    var onSurfaceColor = UIColor(hex: "#212328")
    var onSurface70Color = UIColor(hex: "#212328", alpha: 0.7)
    var onSurface60Color = UIColor(hex: "#212328", alpha: 0.6)
    var onSurface30Color = UIColor(hex: "#212328", alpha: 0.3)
    var onSurface15Color = UIColor(hex: "#212328", alpha: 0.15)
    var onSurface5Color =  UIColor(hex: "#212328", alpha: 0.05)
    var backgroundColor = UIColor(hex: "#F4F4F4")
    var onBackgroundColor = UIColor(hex: "#212328")
    var errorColor = UIColor(hex: "#B00020")
    var errorOnColor = UIColor(hex: "#FFFFFF")
    var onPrimaryColor = UIColor(hex: "#FFFFFF")
    var onPrimaryInvertedColor = UIColor(hex: "#212328")
    var onSurface12Color = UIColor(hex: "#212121", alpha: 0.12)

    var primaryVariantT1Color = UIColor(hex: "#0052AE")
    var primaryColorVariant = UIColor(hex: "#FFFFFF")
    var primaryT1Color = UIColor(hex: "#1F74DB")
    var primary30T1Color = UIColor(hex: "#1F74DB", alpha: 0.3)
    var primary15T1Color = UIColor(hex: "#1F74DB", alpha: 0.15)
    var dividerColor = UIColor(hex: "#DEDEDF")
    var videoShutterColor = UIColor(hex: "#F34139")
    var photoShutterColor = UIColor(hex: "#1F74DB")
    var taskErrorContainer = UIColor(hex: "#BA1B1B", alpha: 0.24)
    var taskWarningContainer = UIColor(hex: "#C95100", alpha: 0.24)
    var taskSuccessContainer = UIColor(hex: "#00754A", alpha: 0.24)
    var taskErrorTextColor = UIColor(hex: "#680003")
    var taskWarningTextColor = UIColor(hex: "#6A3C00")
    var taskSuccessTextColor = UIColor(hex: "#003A02")
    var neutral95Color = UIColor(hex: "#EFF1F1")
    var onSurface12TextColor = UIColor(hex: "#262626")
}
