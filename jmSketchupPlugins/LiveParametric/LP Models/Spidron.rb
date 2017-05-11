require 'liveParametric'

include Geom

class Spidron < LiveParametric
    @@sideNumStr = 'Number of Sides'
    @@depthStr = 'Depth'

    def default_variables
        [
            Slider.new( @@sideNumStr, 4, 12, 6, true),
            Slider.new( @@depthStr,   2, 30, 4, true)
        ]
    end

    def create_entities( data, container)
        sides = data[@@sideNumStr]
        depth = data[@@depthStr]

        2.times{|e|
            otherAngle = 360.degrees/(2*sides)*e
            rad = 10.cm/Math.cos(360.degrees/(2*sides))

            points = (0...sides).map{|i|
                angle = 360.degrees/sides*i + otherAngle
                Point3d.rTheta( rad, angle)
            }

            # draw the outer shape
            container.add_edges( points + [points[0]])

            depth.times { |n|
                newPoints = (0...sides).map { |i|
                    Geom::intersect_line_line( [ points[i-3], points[i-1]], [points[i-2], points[i]])
                }

                points.each_index { |i|  container.add_line( points[i-2], newPoints[i])}
                points = newPoints
            }
        }
    end
end
