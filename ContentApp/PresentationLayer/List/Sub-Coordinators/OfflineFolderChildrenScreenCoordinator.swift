//
// Copyright (C) 2005-2021 Alfresco Software Limited.
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

class OfflineFolderChildrenScreenCoordinator: Coordinator {
    private let presenter: UINavigationController
    private var listNode: ListNode
    private var offlineFolderChildrenScreenCoordinator: OfflineFolderChildrenScreenCoordinator?
    private var actionMenuCoordinator: ActionMenuScreenCoordinator?
    private var filePreviewCoordinator: FilePreviewScreenCoordinator?
    var nodeActionsModel: NodeActionsViewModel?
    private var createNodeSheetCoordinator: CreateNodeSheetCoordinator?

    init(with presenter: UINavigationController, listNode: ListNode) {
        self.presenter = presenter
        self.listNode = listNode
    }

    func start() {
        let offlineViewModelFactory = OfflineFolderChildrenViewModelFactory(services: coordinatorServices)
        let viewModel = offlineViewModelFactory.offlineDataSource(for: listNode)

        let viewController = ListViewController()
        viewController.title = listNode.title
        AnalyticsManager.shared.pageViewEvent(for: Event.Page.personalFiles)

        let pageController = ListPageController(dataSource: viewModel.model,
                                                services: coordinatorServices)

        viewController.pageController = pageController
        viewController.viewModel = viewModel
        
        viewController.coordinatorServices = coordinatorServices
        viewController.listItemActionDelegate = self

        presenter.pushViewController(viewController, animated: true)
    }
}

extension OfflineFolderChildrenScreenCoordinator: ListItemActionDelegate {
    func showPreview(for node: ListNode,
                     from dataSource: ListComponentModelProtocol) {
        if node.isAFolderType() {
            let coordinator = OfflineFolderChildrenScreenCoordinator(with: presenter,
                                                                     listNode: node)
            coordinator.start()
            self.offlineFolderChildrenScreenCoordinator = coordinator
        } else if node.isAFileType() {
            let coordinator = FilePreviewScreenCoordinator(with: presenter,
                                                           listNode: node,
                                                           excludedActions: [.markOffline,
                                                                             .removeOffline,
                                                                             .moveTrash,
                                                                             .addFavorite,
                                                                             .removeFavorite],
                                                           shouldPreviewLatestContent: false)
            coordinator.start()
            self.filePreviewCoordinator = coordinator
        } else {
            AlfrescoLog.error("Unable to show preview for unknown node type")
        }
    }

    func showActionSheetForListItem(for node: ListNode,
                                    from dataSource: ListComponentModelProtocol,
                                    delegate: NodeActionsViewModelDelegate) {
        let actionMenuViewModel = ActionMenuViewModel(node: node,
                                                      coordinatorServices: coordinatorServices,
                                                      excludedActionTypes: [.markOffline,
                                                                            .removeOffline,
                                                                            .moveTrash,
                                                                            .addFavorite,
                                                                            .removeFavorite])
        let nodeActionsModel = NodeActionsViewModel(node: node,
                                                    delegate: delegate,
                                                    coordinatorServices: coordinatorServices)
        nodeActionsModel.moveDelegate = self
        let coordinator = ActionMenuScreenCoordinator(with: presenter,
                                                      actionMenuViewModel: actionMenuViewModel,
                                                      nodeActionViewModel: nodeActionsModel)
        coordinator.start()
        actionMenuCoordinator = coordinator
    }
    
    func moveNodeTapped(for sourceNode: ListNode,
                        destinationNode: ListNode,
                        delegate: NodeActionsViewModelDelegate,
                        actionMenu: ActionMenu) {
        let nodeActionsModel = NodeActionsViewModel(node: sourceNode,
                                                    delegate: delegate,
                                                    coordinatorServices: coordinatorServices)
        nodeActionsModel.moveFilesAndFolder(with: sourceNode, and: destinationNode, action: actionMenu)
        self.nodeActionsModel = nodeActionsModel
    }

    func renameNodeForListItem(for node: ListNode?, actionMenu: ActionMenu,
                               delegate: CreateNodeViewModelDelegate?) {
        if let node = node {
            let coordinator = CreateNodeSheetCoordinator(with: self.presenter,
                                                         actionMenu: actionMenu,
                                                         parentListNode: node,
                                                         createNodeViewModelDelegate: delegate,
                                                         createNodeViewType: .rename)
            coordinator.start()
            createNodeSheetCoordinator = coordinator
        }
    }
}

extension OfflineFolderChildrenScreenCoordinator: NodeActionMoveDelegate {
    func didSelectMoveFile(node: ListNode?, action: ActionMenu) {
        let navigationViewController = self.presenter
        let controller = FilesandFolderListViewController.instantiateViewController()
        controller.sourceNodeToMove = node
        let navController = UINavigationController(rootViewController: controller)
        navigationViewController.present(navController, animated: true)
    }
}
