//
//  GameViewController.swift
//  Assignment 2
//
//  Created by Delaine Tan on 2024-02-20.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    let scene = SCNScene(named: "art.scnassets/main.scn")!
    var rotAngle = 0.0 // Keep track of crate rotation angle
    let mazeRows = 5;
    let mazeCols = 5;
    var isDaytime = true // Flag to track if it's daytime or nighttime
    let ambientLightNode = SCNNode()
    var scnView: SCNView?
    var lastPanLocation: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        scnView = self.view as? SCNView
        
        guard let scnView = scnView else {
            print("scnView is nil")
            return
        }
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // add camera facing start of maze
        // Create a camera node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()

        // Set the position of the camera at the entrance of the maze
        let entrancePosition = SCNVector3(x: 0, y: 0, z: 0) // Assuming entrance is at the origin (adjust as needed)
        let cameraOffset = SCNVector3(x: 0, y: 1, z: -5) // Adjust the offset to position the camera correctly
        cameraNode.position = SCNVector3(
            x: entrancePosition.x + cameraOffset.x,
            y: entrancePosition.y + cameraOffset.y,
            z: entrancePosition.z + cameraOffset.z
        )

        // Set the orientation of the camera to face inside the maze
        cameraNode.eulerAngles = SCNVector3(x: 0, y: .pi, z: 0) // Rotate the camera 180 degrees around the y-axis

        // Add the camera node to the scene
        scene.rootNode.addChildNode(cameraNode)

        // Set the scene's default camera
        scnView.pointOfView = cameraNode
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // Create rotating crate at 0,0 (start of maze)
        addCube()
        reanimate()
        
        // Create the maze node
        let mazeNode = createMazeNode()
        
        // Add the maze node to the scene
        scene.rootNode.addChildNode(mazeNode)
        
        // Add button to toggle day/night
        let toggleButton = UIButton(type: .system)
        toggleButton.setTitle("Toggle Day/Night", for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleDayNight), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleButton)
        
        // Add constraints for button position
        NSLayoutConstraint.activate([
            toggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // Add pan gesture recognizer for movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)

        // Add double tap gesture recognizer for reset
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scnView.addGestureRecognizer(doubleTapGesture)
    }
    
    
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: scnView)
        let location = gestureRecognizer.location(in: scnView)
        
        if let lastPanLocation = lastPanLocation {
            // Calculate the difference in movement
            let deltaX = Float(location.x - lastPanLocation.x)
            let deltaY = Float(location.y - lastPanLocation.y)
            print(deltaX, "|", deltaY)
            // Adjust the camera position based on the movement
            let currentPosition = scnView?.pointOfView!.position

            guard let currentPosition = currentPosition else {
                print("current position is nil")
                // Handle the case where currentPosition is nil
                return
            }
            let newPosition = SCNVector3(currentPosition.x + deltaX * 0.01, currentPosition.y, currentPosition.z - deltaY * 0.01)
            scnView?.pointOfView!.position = newPosition
        }
        
        // Update last pan location
        lastPanLocation = location
        
        if gestureRecognizer.state == .ended {
            // Reset last pan location when gesture ends
            lastPanLocation = nil
        }
    }
    
    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // Reset the camera position to the default view
        let entrancePosition = SCNVector3(x: 0, y: 0, z: 0) // Assuming entrance is at the origin (adjust as needed)
        let cameraOffset = SCNVector3(x: 0, y: 1, z: -5) // Adjust the offset to position the camera correctly
        scnView?.pointOfView!.position = SCNVector3(
            x: entrancePosition.x + cameraOffset.x,
            y: entrancePosition.y + cameraOffset.y,
            z: entrancePosition.z + cameraOffset.z
        )
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    func createMazeNode() -> SCNNode {
        let mazeNode = SCNNode()
        
        var maze = Maze(Int32(mazeRows), Int32(mazeCols))
        maze.Create()
        
        // Define the size of a single cell, padding, and wall thickness
        let cellSize: CGFloat = 1.0
        let wallThickness: CGFloat = 0.1
        // Adjust the position of the walls to avoid perfect overlap
        let wallOffset: Float = -0.05 // Adjust as needed

        // Load the floor texture image
        let floorTexture = UIImage(named: "floor.png") // Replace "floorTexture.jpg" with the actual name of your floor texture image
        
        // Define textures for different wall configurations
        let noWallTexture = "no_walls.jpeg"
        let leftWallTexture = "left_wall.jpeg"
        let rightWallTexture = "right_wall.jpeg"
        let bothWallsTexture = "both_walls.jpeg"
        
        // Iterate through maze cells
        for row in 0..<maze.rows {
            for col in 0..<maze.cols {
                let cell = maze.GetCell(row, col)
                let cellPosition = SCNVector3(CGFloat(col) * (cellSize), 0, CGFloat(row) * (cellSize))
                
                // Create a node for the cell
                let cellGeometry = SCNBox(width: cellSize, height: 0.0, length: cellSize, chamferRadius: 0)
                let cellNode = SCNNode(geometry: cellGeometry)
                cellNode.position = SCNVector3(CGFloat(col) * cellSize, -0.5, CGFloat(row) * cellSize)

                // Apply floor texture to the cell
                let material = SCNMaterial()
                material.diffuse.contents = floorTexture
                cellNode.geometry?.firstMaterial = material
                
                mazeNode.addChildNode(cellNode)
                
                // Check walls and create them if present
                if cell.northWallPresent {
                    var textureName = noWallTexture
                    // East is left of north, west is right of north
                    if cell.eastWallPresent && cell.westWallPresent {
                        textureName = bothWallsTexture
                    } else if cell.westWallPresent {
                        textureName = rightWallTexture
                    } else if cell.eastWallPresent {
                        textureName = leftWallTexture
                    }
                    
                    // Create north wall with offset
                    let northWallNode = createWall(position: SCNVector3(cellPosition.x, Float(wallThickness)/2, cellPosition.z - Float(cellSize/2) - wallOffset),
                                                   width: cellSize, height: 1, length: wallThickness, textureName: textureName, inScene: scene)
                    mazeNode.addChildNode(northWallNode)
                }
                if cell.southWallPresent {
                    var textureName = noWallTexture
                    // West is left of south, east is right of south
                    if cell.westWallPresent && cell.eastWallPresent {
                        textureName = bothWallsTexture
                    } else if cell.westWallPresent {
                        textureName = leftWallTexture
                    } else if cell.eastWallPresent {
                        textureName = rightWallTexture
                    }
                    
                    // Create south wall with offset
                    let southWallNode = createWall(position: SCNVector3(cellPosition.x, Float(wallThickness)/2, cellPosition.z + Float(cellSize)/2 + wallOffset),
                                                   width: cellSize, height: 1, length: wallThickness, textureName: textureName, inScene: scene)
                    mazeNode.addChildNode(southWallNode)
                }
                if cell.eastWallPresent {
                    var textureName = noWallTexture
                    // South is left of east, north is right of east
                    if cell.southWallPresent && cell.northWallPresent {
                        textureName = bothWallsTexture
                    } else if cell.southWallPresent {
                        textureName = leftWallTexture
                    } else if cell.northWallPresent {
                        textureName = rightWallTexture
                    }
                    
                    // Create east wall with offset
                    let eastWallNode = createWall(position: SCNVector3(cellPosition.x + Float(cellSize)/2 + wallOffset, Float(wallThickness)/2, cellPosition.z),
                                                  width: wallThickness, height: 1, length: cellSize, textureName: textureName, inScene: scene)
                    mazeNode.addChildNode(eastWallNode)
                }
                if cell.westWallPresent {
                    var textureName = noWallTexture
                    // North is left of west, south is right of west
                    if cell.northWallPresent && cell.southWallPresent {
                        textureName = bothWallsTexture
                    } else if cell.southWallPresent {
                        textureName = rightWallTexture
                    } else if cell.northWallPresent {
                        textureName = leftWallTexture
                    }
                    
                    // Create west wall with offset
                    let westWallNode = createWall(position: SCNVector3(cellPosition.x - Float(cellSize)/2 - wallOffset, Float(wallThickness)/2, cellPosition.z),
                                                  width: wallThickness, height: 1, length: cellSize, textureName: textureName, inScene: scene)
                    mazeNode.addChildNode(westWallNode)
                }
            }
        }
        
        return mazeNode
    }
    
    func createWall(position: SCNVector3, width: CGFloat, height: CGFloat, length: CGFloat, textureName: String, inScene scene: SCNScene) -> SCNNode {
        let wallNode = SCNNode(geometry: SCNBox(width: width, height: height, length: length, chamferRadius: 0))
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: textureName)
        wallNode.geometry?.firstMaterial = material
        wallNode.position = position
        return wallNode
    }
    
    
    func addCube() {
        let theCube = SCNNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0)) // Create a object node of box shape with width of 1 and height of 1
        theCube.name = "The Cube" // Name the node so we can reference it later
        theCube.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "crate.jpg") // Diffuse the crate image material across the whole cube
        theCube.position = SCNVector3(0, 0, 0) // Put the cube at position (0, 0, 0)
        scene.rootNode.addChildNode(theCube) // Add the cube node to the scene
    }
    
    @MainActor
    func reanimate() {
        let theCube = scene.rootNode.childNode(withName: "The Cube", recursively: true) // Get the cube object by its name (This is where line 40 comes in)
        rotAngle += 0.0005 // Increment rotation of the cube by 0.0005 radians
        // Keep the rotation angle in the range of 0 and pi
        if rotAngle > Double.pi {
            rotAngle -= Double.pi
        }
        theCube?.eulerAngles = SCNVector3(0, rotAngle, 0) // Rotate cube by the final amount
        // Repeat increment of rotation every 10000 nanoseconds
        Task { try! await Task.sleep(nanoseconds: 10000)
            reanimate()
        }
    }
    
    // Method to toggle day and night
    @objc
    func toggleDayNight() {
        if isDaytime {
            // Set nighttime color
            ambientLightNode.light?.color = UIColor.darkGray
        } else {
            // Set daytime color
            ambientLightNode.light?.color = UIColor.white
        }
        isDaytime = !isDaytime // Toggle the flag
    }
}
