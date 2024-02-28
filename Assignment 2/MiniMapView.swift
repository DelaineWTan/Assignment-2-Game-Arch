import UIKit
import SceneKit

class MiniMapView: UIView {
    var maze: Maze
    var playerPosition: SCNVector3?
    
    init(frame: CGRect, maze: Maze, initialPlayerPosition: SCNVector3) {
        self.maze = maze
        super.init(frame: frame)
        self.playerPosition = initialPlayerPosition
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
        
        // Highlight player position
        if let playerPos = playerPosition {
            let playerCol = Int(round(playerPos.x + 0.4))
            let playerRow = Int(round(playerPos.z - 0.5) + 1)
            let x = CGFloat(playerCol) * cellWidth
            let y = CGFloat(playerRow) * cellHeight
            let playerRect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            
            context.setFillColor(UIColor.green.cgColor)
            context.fill(playerRect)
        }
    }
    
    func updatePlayerPosition(_ newPosition: SCNVector3) {
        playerPosition = newPosition
        setNeedsDisplay() // Request a redraw
    }
}
