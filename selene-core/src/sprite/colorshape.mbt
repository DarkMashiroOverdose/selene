//加入一系列可以定义渲染形状的结构体
pub enum Shape {
  Rect(Double, Double)
  Circle(Double)
  Ellipse(Double, Double, Double)
}
pub fn Shape::rect(width: Double, height: Double) -> Shape { Rect(width, height) }
pub fn Shape::circle(radius: Double) -> Shape { Circle(radius) }
pub fn Shape::ellipse(radius_x: Double, radius_y: Double, rotation: Double) -> Shape { Ellipse(radius_x, radius_y, rotation) }

pub enum DrawStyle {
  Fill(String)
  Stroke(String, Double) // color, line_width
}


pub fn DrawStyle::fill(color: String) -> DrawStyle { Fill(color) }
pub fn DrawStyle::stroke(color: String, line_width: Double) -> DrawStyle { Stroke(color, line_width) }

pub struct ColoredShape {
  shape: Shape
  style: DrawStyle
}

pub fn ColoredShape::new(shape: Shape, style: DrawStyle) -> ColoredShape {
  { shape, style }
}

fn render_colored_shape(
  backend: &@system.Backend,
  graphic: ColoredShape,
  position: @math.Vec2D,
) -> Unit {
  match graphic.style {
    Fill(color) => {
      match graphic.shape {
        Rect(width, height) => 
          backend.draw_color_rect(
            x=position[X], y=position[Y], 
            width=width, height=height, 
            color=color,
          )
        Circle(radius) => 
          backend.draw_filled_circle(
            x=position[X], y=position[Y], 
            radius=radius, 
            color=color,
          )
        Ellipse(radius_x, radius_y, rotation) => 
          backend.draw_filled_ellipse(
            x=position[X], y=position[Y], 
            radius_x=radius_x, radius_y=radius_y, 
            rotation=rotation, 
            color=color,
          )
      }
    }
    Stroke(color, line_width) => {
      match graphic.shape {
        Rect(width, height) => 
          backend.draw_rect_outline(
            x=position[X], y=position[Y], 
            width=width, height=height, 
            color=color, line_width=line_width,
          )
        Circle(radius) => 
          backend.draw_stroke_circle(
            x=position[X], y=position[Y], 
            radius=radius, 
            color=color, line_width=line_width,
          )
        Ellipse(radius_x, radius_y, rotation) => 
          backend.draw_stroke_ellipse(
            x=position[X], y=position[Y], 
            radius_x=radius_x, radius_y=radius_y, 
            rotation=rotation, 
            color=color, line_width=line_width,
          )
      }
    }
  }
}