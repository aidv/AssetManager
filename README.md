# AssetManager

AssetManager

What is AssetManager?

AssetManager is a simple asset manager for iOS using Swift 3 that increases flexibility of the asset resource management thingy-thing-unnecessary-complicated(in my opinion)-iOS asset manager.

As you can tell, I'm not too happy with the way you need to recieve an asset in iOS as of right now.



How does AssetManager work and how do I use it?

AssetManager allows you to read chunks of data from an asset.
You specify the size of the chunks and then choose which chunk in the data you want to extract.

For example:
Let's say your device contains a photo which is 3 MB.
If you set your AssetManager chunk size to 1 MB, that means that you can extract chunk 0, chunk 1 and chunk 2.

You can also calculate the count of chunks for a specific asset.

This type of system is amazingly useful for full control over your assets if you want to send them over a network.

Below is sample code with comments.

The code will set a desired chunk size, followed by extracting a chunk of data from an asset.


    /*  myViewController.swift
        AssetManager Example
    
        Created by Aid Vllasaliu on 2016-11-23.
        Copyright © 2016 Aid Vllasaliu. All rights reserved.
    
        License: GNU GPLv3
    
    */

    import UIKit
    import Photos

    class myViewController: UIViewController, assetManagerNotificationProtocol {
        let aS = assetManager() //the asset manager
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.
            
            assetManagerChunkSize = 5000000 //set chunk size to 5 MB
            aS.assembleAssets() //assemble all assets in device
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        
        func onAssemblyComplete() {
            print("Asset assembly Done!")
            
            //extract the first chunk of data from the first asset
            aS.asset(0).extractData(chunkIndex: 0,
                    
                                    chunkComplete: {(info: extractionResults) -> Void in
                                        //this is called when the chunk has been extracted
                                    },
                    
                                    extractionComplete: {(info: extractionResults) -> Void in
                                        //this is called when the very last piece of data has been extracted
                                        //which is contained in the last chunk.
                                    }
        )
        }
        
        func onAssetAssembled(asset: assetInfo){
            print("1 asset added!");
            
            //print some info about the newly added asset
            print(asset.filename + " size is " + String(asset.size) + " Bytes. " + String(asset.chunkCount()) + " chunks available.")
        }

    }
