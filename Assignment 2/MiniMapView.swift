import UIKit
import SceneKit

class MiniMapView: UIView {
    var maze: Maze
    var playerPosition: SCNVector3?
    var playerRotation: SCNVector3?
    
    init(frame: CGRect, maze: Maze, initialPlayerPosition: SCNVector3, initialPlayerRotation: SCNVector3) {
        self.maze = maze
        super.init(frame: frame)
        self.playerPosition = initialPlayerPosition
        self.playerRotation = initialPlayerRotation
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let numRows = maze.rows
        let numCols = maze.cols
        
        let cellWidth = rect.width / CGFloat(numCols)
        let cellHeight = rect.height / CGFloat(numRows)
        
        // Draw grid lines
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        
        // Draw horizontal lines and color-coded walls
        for row in 0..<numRows {
            for col in 0..<numCols {
                let cell = maze.GetCell(row, col)
                let x = CGFloat(col) * cellWidth
                let y = CGFloat(row) * cellHeight
                
                // Draw walls based on maze configuration with color coding
                if cell.northWallPresent {
                    context.setStrokeColor(UIColor.red.cgColor) // Wall facing up
                    context.move(to: CGPoint(x: x, y: y))
                    context.addLine(to: CGPoint(x: x + cellWidth, y: y))
                    context.strokePath()
                }
                if cell.southWallPresent {
                    context.setStrokeColor(UIColor.blue.cgColor) // Wall facing down
                    context.move(to: CGPoint(x: x, y: y + cellHeight))
                    context.addLine(to: CGPoint(x: x + cellWidth, y: y + cellHeight))
                    context.strokePath()
                }
                if cell.westWallPresent {
                    context.setStrokeColor(UIColor.green.cgColor) // Wall facing left
                    context.move(to: CGPoint(x: x, y: y))
                    context.addLine(to: CGPoint(x: x, y: y + cellHeight))
                    context.strokePath()
                }
                if cell.eastWallPresent {
                    context.setStrokeColor(UIColor.orange.cgColor) // Wall facing right
                    context.move(to: CGPoint(x: x + cellWidth, y: y))
                    context.addLine(to: CGPoint(x: x + cellWidth, y: y + cellHeight))
                    context.strokePath()
                }
            }
        }
        
        // Highlight player position with a triangle indicating the camera's direction
        if let playerPos = playerPosition, let playerRot = playerRotation {
            let playerCol = Int(round(playerPos.x + 0.4))
            let playerRow = Int(round(playerPos.z - 0.5) + 1)
            let x = CGFloat(playerCol) * cellWidth
            let y = CGFloat(playerRow) * cellHeight
            
            // Calculate the angle to rotate the triangle
            let angle = playerRot.y
            
            // Rotate the context around the triangle's center
            let centerX = x + cellWidth / 2
            let centerY = y + cellHeight / 2
            context.translateBy(x: centerX, y: centerY)
            context.rotate(by: CGFloat(angle))
            context.translateBy(x: -centerX, y: -centerY)
            
            // Draw triangle
            context.beginPath()
            context.move(to: CGPoint(x: x + cellWidth / 2, y: y)) // Top vertex
            context.addLine(to: CGPoint(x: x + cellWidth / 3, y: y + cellHeight)) // Bottom-left vertex
            context.addLine(to: CGPoint(x: x + cellWidth * 2 / 3, y: y + cellHeight) ) // Bottom-right vertex
            context.closePath()
            
            context.setFillColor(UIColor.green.cgColor)
            context.fillPath()
        }
        
    }
    
    func updatePlayerPosition(_ newPosition: SCNVector3, newRotation: SCNVector3) {
        playerPosition = newPosition
        playerRotation = newRotation
        
        setNeedsDisplay() // Request a redraw
    }
}
