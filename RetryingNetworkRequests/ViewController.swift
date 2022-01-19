//
//  ViewController.swift
//  RetryingNetworkRequests
//
//  Created by Зафар Иваев on 18/01/22.
//

import UIKit
import Combine

enum CustomError: Error {
    case dataCorrupted
    case serverFailure
}

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        getAvatarFromTheServer()
            .handleEvents(receiveSubscription: { print("Subscribed", $0)}, receiveOutput: { print("Got image", $0)}, receiveCompletion: { print("Completion", $0)})
            .delay(for: 1, scheduler: DispatchQueue.global())
            .retry(3)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    print("Finished with error: \(error)")
                case .finished:
                    print("Finished")
                }
            }, receiveValue: { [weak self] image in
                self?.imageView.image = image
            })
            .store(in: &cancellables)
    }
    
    private func getAvatarFromTheServer() -> AnyPublisher<UIImage, Error> {
        
        let url = URL(string: "https://picsum.photos/1000")!
        
        return Deferred {
            Future { promise in
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                          promise(.failure(CustomError.dataCorrupted))
                          return
                      }
                
                promise(.success(image))
            }
        }.eraseToAnyPublisher()
    }

}

