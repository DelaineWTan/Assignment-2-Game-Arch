//
//  GameViewController.swift
//  Assignment 2
//
//  Created by Delaine Tan on 2024-02-20.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, UIGestureRecognizerDelegate {
    let scene = SCNScene(named: "art.scnassets/main.scn")!
    var rotAngle = 0.0 // Keep track of crate rotation angle
    let mazeRows = 5;
    let mazeCols = 5;
    var isDaytime = true // Flag to track if it's daytime or nighttime
    let cameraNode = SCNNode()
    let ambientLightNode = SCNNode()
    var flashlightNode = SCNNode()
    var scnView: SCNView?
    var lastPanLocation: CGPoint?
    // Fog variables
    var fogSwitch: UISwitch!
    var fogStartTextField: UITextField!
    var fogEndTextField: UITextField!
    var fogDensityTextField: UITextField!
    var isFogEnabled = false;
    var consoleView: UIView?
    var isConsoleVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // black background
        scene.background.contents = UIColor.black
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
        
        cameraNode.camera = SCNCamera()
        
        // Set the position of the camera at the entrance of the maze
        let entrancePosition = SCNVector3(x: 0, y: 0, z: 0) // Assuming entrance is at the origin (adjust as needed)
        let cameraOffset = SCNVector3(x: 0, y: 0.2, z: -3)
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
        
        // Add flashlight & fog controls
        addFlashlight()
        addFogControls()
        
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
        
        // Add a two-finger double-tap gesture recognizer
        let twoFingerDoubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerDoubleTap(_:)))
        twoFingerDoubleTapGesture.numberOfTapsRequired = 2
        twoFingerDoubleTapGesture.numberOfTouchesRequired = 2
        twoFingerDoubleTapGesture.delegate = self
        view.addGestureRecognizer(twoFingerDoubleTapGesture)
        
        // Initialize the console view
        consoleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 200))
        consoleView?.backgroundColor = UIColor.white
        consoleView?.alpha = 0.0 // Initially hidden
        view.addSubview(consoleView!)
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
        let location = gestureRecognizer.location(in: scnView)
        
        if let lastPanLocation = lastPanLocation {
            // Calculate the difference in movement
            let deltaX = Float(location.x - lastPanLocation.x)
            let deltaY = Float(location.y - lastPanLocation.y)
            
            // Adjust the camera position based on the movement
            guard let cameraNode = scnView?.pointOfView else {
                return
            }
            
            // Adjust player position forward and backward along the X-axis
            let xDelta = deltaY * 0.01 // deltaY corresponds to vertical movement
            let currentRotationY = cameraNode.eulerAngles.y
            let newX = cameraNode.position.x - sin(currentRotationY) * xDelta
            let newZ = cameraNode.position.z - cos(currentRotationY) * xDelta
            cameraNode.position = SCNVector3(newX, cameraNode.position.y, newZ)
            
            // Adjust player rotation left and right along the Y-axis
            let yDelta = deltaX * 0.01 // deltaX corresponds to horizontal movement
            cameraNode.eulerAngles.y += yDelta
            
            // Ensure that the player's rotation remains within a reasonable range
            if cameraNode.eulerAngles.y > .pi {
                cameraNode.eulerAngles.y -= .pi * 2
            } else if cameraNode.eulerAngles.y < -.pi {
                cameraNode.eulerAngles.y += .pi * 2
            }
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
        let entrancePosition = SCNVector3(x: 0, y: 0, z: 0) // Assuming entrance is at the origin
        let cameraOffset = SCNVector3(x: 0, y: 0.2, z: -3)
        scnView?.pointOfView!.position = SCNVector3(
            x: entrancePosition.x + cameraOffset.x,
            y: entrancePosition.y + cameraOffset.y,
            z: entrancePosition.z + cameraOffset.z
        )
        // Set the orientation of the camera to face inside the maze
        scnView?.pointOfView!.eulerAngles = SCNVector3(x: 0, y: .pi, z: 0)
    }
    
    // Handle the two-finger double-tap gesture
    @objc func handleTwoFingerDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if isConsoleVisible {
            hideConsole()
        } else {
            showConsole()
        }
    }
    
    // Show the console view
    func showConsole() {
        UIView.animate(withDuration: 0.3) {
            self.consoleView?.alpha = 1.0
        }
        isConsoleVisible = true
    }
    
    // Hide the console view
    func hideConsole() {
        UIView.animate(withDuration: 0.3) {
            self.consoleView?.alpha = 0.0
        }
        isConsoleVisible = false
    }
    
    // Allow simultaneous recognition of multiple gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
        let floorTexture = UIImage(named: "floor.png")
        
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
    
    // Sets up a flashlight
    func addFlashlight() {
        flashlightNode.name = "Flashlight"
        flashlightNode.light = SCNLight()
        flashlightNode.light!.type = SCNLight.LightType.spot
        flashlightNode.light!.castsShadow = true
        flashlightNode.light!.color = UIColor.yellow
        flashlightNode.light!.intensity = 5000
        flashlightNode.position = SCNVector3(0, 5, 3)
        flashlightNode.rotation = SCNVector4(1, 0, 0, -Double.pi/3)
        flashlightNode.light!.spotInnerAngle = 0
        flashlightNode.light!.spotOuterAngle = 10
        flashlightNode.light!.shadowColor = UIColor.black
        flashlightNode.light!.zFar = 500
        flashlightNode.light!.zNear = 50
        scene.rootNode.addChildNode(flashlightNode)
    }
    
    func addFogControls() {
        // Add switch for toggling fog
        fogSwitch = UISwitch()
        fogSwitch.isOn = false // Fog is initially off
        fogSwitch.addTarget(self, action: #selector(fogSwitchChanged(_:)), for: .valueChanged)
        fogSwitch.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fogSwitch)
        
        // Add label for fog switch
        let fogSwitchLabel = UILabel()
        fogSwitchLabel.text = "Toggle Fog"
        fogSwitchLabel.textColor = UIColor.white
        fogSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fogSwitchLabel)
        
        // Add text fields for fog parameters
        fogDensityTextField = addTextField(placeholder: "Fog Density", defaultValue: "0.1", action: #selector(fogDensityTextChanged(_:)))
        fogStartTextField = addTextField(placeholder: "Fog Start Distance", defaultValue: "10", action: #selector(fogStartTextChanged(_:)))
        fogEndTextField = addTextField(placeholder: "Fog End Distance", defaultValue: "50", action: #selector(fogEndTextChanged(_:)))
        
        // Add labels for text fields
        let fogDensityLabel = addLabel(text: "Fog Density", textColor: UIColor.white)
        let fogStartLabel = addLabel(text: "Fog Start Distance", textColor: UIColor.white)
        let fogEndLabel = addLabel(text: "Fog End Distance", textColor: UIColor.white)
        
        // Layout constraints for fog controls
        NSLayoutConstraint.activate([
            fogSwitch.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            fogSwitch.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            fogSwitchLabel.topAnchor.constraint(equalTo: fogSwitch.topAnchor),
            fogSwitchLabel.leadingAnchor.constraint(equalTo: fogSwitch.trailingAnchor, constant: 8),
            
            fogDensityLabel.topAnchor.constraint(equalTo: fogSwitch.bottomAnchor, constant: 20),
            fogDensityLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            fogDensityTextField.topAnchor.constraint(equalTo: fogDensityLabel.bottomAnchor, constant: 8),
            fogDensityTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            fogStartLabel.topAnchor.constraint(equalTo: fogDensityTextField.bottomAnchor, constant: 20),
            fogStartLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            fogStartTextField.topAnchor.constraint(equalTo: fogStartLabel.bottomAnchor, constant: 8),
            fogStartTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            fogEndLabel.topAnchor.constraint(equalTo: fogStartTextField.bottomAnchor, constant: 20),
            fogEndLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            fogEndTextField.topAnchor.constraint(equalTo: fogEndLabel.bottomAnchor, constant: 8),
            fogEndTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        ])
    }
    
    func addTextField(placeholder: String, defaultValue: String, action: Selector) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.text = defaultValue
        textField.addTarget(self, action: action, for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = UIColor.gray
        view.addSubview(textField)
        return textField
    }
    
    
    func addLabel(text: String, textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        return label
    }
    
    @objc func fogSwitchChanged(_ sender: UISwitch) {
        // Toggle fog on/off based on switch state
        if sender.isOn {
            enableFog()
        } else {
            disableFog()
        }
    }
    
    func enableFog() {
        guard let fogDensityText = fogDensityTextField.text,
              let fogDensityValue = Float(fogDensityText),
              let fogStartText = fogStartTextField.text,
              let fogStartValue = Float(fogStartText),
              let fogEndText = fogEndTextField.text,
              let fogEndValue = Float(fogEndText) else {
            print("Invalid fog parameter values")
            return
        }
        // Set fog values in the scene
        scene.fogStartDistance = CGFloat(fogStartValue)
        scene.fogEndDistance = CGFloat(fogEndValue)
        scene.fogDensityExponent = CGFloat(fogDensityValue)
        scene.fogColor = UIColor.white
        isFogEnabled = true
    }
    
    func disableFog() {
        // Reset fog-related properties
        scene.fogStartDistance = 0
        scene.fogEndDistance = 0
        scene.fogDensityExponent = 0 // Reset fog density
        scene.fogColor = UIColor.clear
        isFogEnabled = false
        
        // Print debug information
        print("Fog disabled. Fog parameters reset.")
    }
    
    @objc func fogDensityTextChanged(_ sender: UITextField) {
        guard let text = sender.text, let density = Float(text) else { return }
        scene.fogDensityExponent = CGFloat(density)
    }
    
    @objc func fogStartTextChanged(_ sender: UITextField) {
        guard let text = sender.text, let start = Float(text) else { return }
        scene.fogStartDistance = CGFloat(start)
    }
    
    @objc func fogEndTextChanged(_ sender: UITextField) {
        guard let text = sender.text, let end = Float(text) else { return }
        scene.fogEndDistance = CGFloat(end)
    }
}
