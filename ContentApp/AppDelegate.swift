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
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var applicationCoordinator: ApplicationCoordinator?
    var orientationLock = UIInterfaceOrientationMask.all
    var enterInBackgroundTimestamp: TimeInterval?
    var enterInForegroundTimestamp: TimeInterval?
    var logoutActionFlow = false
    var isMoveFilesAndFolderFlow = false
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { // swiftlint:disable:this discouraged_optional_collection
        let window = UIWindow(frame: UIScreen.main.bounds)
        let applicationCoordinator = ApplicationCoordinator(window: window)

        self.window = window
        self.applicationCoordinator = applicationCoordinator
        let repository = applicationCoordinator.repository

        if let themingService = repository.service(of: MaterialDesignThemingService.identifier) as? MaterialDesignThemingService {
            window.backgroundColor = themingService.activeTheme?.surfaceColor
        }

        applicationCoordinator.start()

        FirebaseApp.configure()
        let connectivityService = repository.service(of: ConnectivityService.identifier) as? ConnectivityService
        connectivityService?.startNetworkReachabilityObserver()
        UserDefaultsModel.set(value: true, for: KeyConstants.AdvanceSearch.fetchAdvanceSearchFromServer)
        migrateDatabaseIfNecessary()
        AnalyticsManager.shared.appLaunched()
        return true
    }

    func migrateDatabaseIfNecessary() {
        let isDataMigrated = UserDefaultsModel.value(for: KeyConstants.AppGroup.dataMigration) as? Bool
        if isDataMigrated == false || isDataMigrated == nil {
            DatabaseMigrationService().migrateDatabase()
        }
    }
    
    // MARK: - Start Sync
    func startSyncOperation() {
        let repository = applicationCoordinator?.repository
        let syncTriggerService = repository?.service(of: SyncTriggersService.identifier) as? SyncTriggersService
        syncTriggerService?.triggerSync(for: .userDidInitiateSync)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let repository = applicationCoordinator?.repository

        let themingService = repository?.service(of: MaterialDesignThemingService.identifier) as? MaterialDesignThemingService
        themingService?.activateAutoTheme(for: UIScreen.main.traitCollection.userInterfaceStyle)

        let accountService = repository?.service(of: AccountService.identifier) as? AccountService
        accountService?.createTicketForCurrentAccount()

        let syncTriggerService = repository?.service(of: SyncTriggersService.identifier) as? SyncTriggersService

        enterInForegroundTimestamp = Date().timeIntervalSince1970

        if let enterInForegroundTimestamp = self.enterInForegroundTimestamp,
           let enterInBackgroundTimestamp = self.enterInBackgroundTimestamp {

            let interval = enterInForegroundTimestamp - enterInBackgroundTimestamp
            syncTriggerService?.triggerSync(for: .applicationDidFinishedLaunching,
                                            in: interval)

            self.enterInForegroundTimestamp = nil
            self.enterInForegroundTimestamp = nil
        }
        
        // ----- migrate data from app extension to the local data base ------ //
        migrateDataFromAppExtension()
    }
    
    // MARK: - Upload nodes migration from app extension
    func migrateDataFromAppExtension() {
        let uploadingNodesFromExtension = SyncSharedNodes.getPendingUploads()
        if !uploadingNodesFromExtension.isEmpty {
            let uploadTransferDataAccessor = UploadTransferDataAccessor()
            let nodes = processUploadingNodes(uploadingNodesFromExtension)
            uploadTransferDataAccessor.store(uploadTransfers: nodes)
            
            // clear user default
            UserDefaultsModel.remove(forKey: KeyConstants.AppGroup.pendingUploadNodes)

            // trigger notification
            SyncBannerService.triggerSyncNotifyService()
        }
    }
    
    fileprivate func processUploadingNodes(_ nodes: [UploadTransfer]) -> [UploadTransfer] {
        var uploadingNodes = [UploadTransfer]()
        if !nodes.isEmpty {
            for node in nodes {
                let nodeToBeStored = node
                if node.id != 0 {
                    nodeToBeStored.id = 0
                }
                uploadingNodes.append(nodeToBeStored)
            }
        }
        return uploadingNodes
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        enterInBackgroundTimestamp = Date().timeIntervalSince1970
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == ConfigurationKeys.urlSchema {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                notificationsCentre().handleNotification(for: url)
             }
            return true
        }
        let accountService = applicationCoordinator?.repository.service(of: AccountService.identifier) as? AccountService
        if let aimsAccount = accountService?.activeAccount as? AIMSAccount {
            if let session = aimsAccount.session.session {
                return session.resumeExternalUserAgentFlow(with: url)
            }
        }

        return false
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == UIApplication.ExtensionPointIdentifier.keyboard {
            return false
        }

        return true
    }
}

// MARK: - APPDELEGATE SINGLETON
func appDelegate() -> AppDelegate? {
    return  UIApplication.shared.delegate as? AppDelegate
}
