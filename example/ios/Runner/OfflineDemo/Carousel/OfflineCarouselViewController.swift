//
//  CarouselViewControler.swift
//  PushSDKApp
//
//  Created by Phil on 26/05/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit

final class OfflineCarouselViewController: UIViewController {
    
    private lazy var response: OfflineVideoNotificationsResponse? = {
        Bundle.main.decode(from: "OfflineCarouselTiles.json")
    }()

    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        carousel?.register(nibForCell: OfflineCarouselNotificationContentCell.self)
        view.addSubview(self.carousel!)
    }

    //MARK: - Outlets
    
    @IBOutlet private weak var carousel: OfflinePSDKScalingCarouselView!
    
    //MARK: - Actions
    
    @IBAction private func closeButtonPressed() {
        navigationController?.dismiss(animated: false)
    }
    
    @IBAction private func nextCarouselItemButtonPressed() {
        carousel.showNextItem()
    }
        
    @IBAction private func previousCarouselItemButtonPressed() {
        carousel.showPreviousItem()
    }
    
    //MARK: - Functions
    
    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
    
    private func readLocalJSON(from file: String) -> OfflineVideoNotificationsResponse? {
        Bundle.main.decode(from: file)
    }
    
}

//MARK: - Collection View DataSource

extension OfflineCarouselViewController: UICollectionViewDataSource, UICollectionViewDelegate {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        response?.notification.contents.count ?? 0
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            of: OfflineCarouselNotificationContentCell.self,
            for: indexPath
        )
        guard let image = response?.notification.contents[indexPath.row].downloadUrl else {
            return UICollectionViewCell()
        }
        cell.configure(image: UIImage(named: image))
        
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let urlString = response?.notification.contents[indexPath.row].options?.buttons?.first?.url else {
            return
        }
        UIApplication.shared.open(URL(string: urlString)!)
    }

}

//MARK: - Scroll View Delegate

extension OfflineCarouselViewController: UIScrollViewDelegate {
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        carousel?.didScroll()
    }
    
}
