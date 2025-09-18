// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|

//本页面所有的self.context均改为self.active_context以支持分层渲染
let element_cache : Map[String, @dom.HTMLImageElement] = Map::new()

//设置渲染层级
pub impl @system.Backend for CanvasBackend with set_render_target(
  self,
  target: String,
) -> Unit {
  match target {
    "world" => self.active_context = self.context
    "ui"    => self.active_context = self.ui_context
    _       => () // 对于未知的 target，安全起见，不做任何操作
  }
}
///|
fn get_image_element(png : String) -> @dom.HTMLImageElement {
  if element_cache.get(png) is Some(element) {
    return element
  }
  let element = @dom.HTMLImageElement::new()
  element.set_src(png)
  element_cache.set(png, element)
  return element
}

///|
pub impl @system.Backend for CanvasBackend with preload_img(
  _self,
  path : String,
) -> Unit {
  get_image_element(path) |> ignore
}

///|
pub impl @system.Backend for CanvasBackend with draw_picture(
  self,
  png,
  x~,
  y~,
  width~,
  height~,
  transform~,
  repeat~,
) {
  let element = get_image_element(png)
  let repeat_mode = match repeat {
    NoRepeat => "no-repeat"
    RepeatY => "repeat-y"
    RepeatX => "repeat-x"
    Repeat => "repeat"
  }
  let pattern = self.active_context.create_pattern(
    @js.Union7::from0(element),
    repeat_mode,
  )
  self.active_context.save()
  self.active_context.set_fill_style(@js.Union3::from2(pattern))
  self.active_context.translate(x, y)
  self.active_context.transform(
    transform.a,
    transform.b,
    transform.c,
    transform.d,
    transform.tx,
    transform.ty,
  )
  self.active_context.fill_rect(0, 0, width, height)
  self.active_context.restore()
}

///|
pub impl @system.Backend for CanvasBackend with draw_sprite(
  self,
  sprite_path,
  x~,
  y~,
  offset_x~,
  offset_y~,
  width~,
  height~,
  transform~,
) {
  self.active_context.save()
  self.active_context.translate(x, y)
  self.active_context.transform(
    transform.a,
    transform.b,
    transform.c,
    transform.d,
    transform.tx,
    transform.ty,
  )
  let element = get_image_element(sprite_path)
  self.active_context.draw_image_with_src_and_dst_size(
    element |> @js.Value::cast_from |> @js.Value::cast,
    offset_x,
    offset_y,
    width,
    height,
    0,
    0,
    width,
    height,
  )
  self.active_context.restore()
}

///|
pub impl @system.Backend for CanvasBackend with draw_stroke_rect(
  self,
  x~,
  y~,
  width~,
  height~,
  color~,
) {
  self.active_context.save()
  self.active_context.set_stroke_style(@js.Union3::from0(color))
  self.active_context.stroke_rect(x, y, width, height)
  self.active_context.restore() 
  self.active_context.stroke() 
}

///|
pub impl @system.Backend for CanvasBackend with draw_text(
  self,
  text,
  x~,
  y~,
  font~,
  color~,
) {
  self.active_context.save()
  self.active_context.set_font(font)
  self.active_context.set_fill_style(@js.Union3::from0(color))
  self.active_context.fill_text(text, x, y)
  self.active_context.restore()
}

///|
pub impl @system.Backend for CanvasBackend with draw_color_rect(
  self,
  x~,
  y~,
  width~,
  height~,
  color~,
) {
  self.active_context.save()
  self.active_context.set_fill_style(@js.Union3::from0(color))
  self.active_context.fill_rect(x, y, width, height)
  self.active_context.restore()
}

///|
pub impl @system.Backend for CanvasBackend with draw_gradient_rect(
  self,
  x~,
  y~,
  width~,
  height~,
  color_start~,
  color_end~,
) {
  self.active_context.save()
  let gradient = self.active_context.create_linear_gradient(
    x,
    y,
    x + width,
    y + height,
  )
  gradient.add_color_stop(0.0, color_start)
  gradient.add_color_stop(1.0, color_end)
  self.active_context.set_fill_style(@js.Union3::from1(gradient))
  self.active_context.fill_rect(x, y, width, height)
  self.active_context.restore()
}
//画圆形
pub impl @system.Backend for CanvasBackend with draw_filled_circle(
  self,
  x~,
  y~,
  radius~,
  color~,
) {
  self.active_context.save()
  self.active_context.begin_path()
  self.active_context.arc(x, y, radius, 0.0, 6.28318530718) 
  self.active_context.set_fill_style(@js.Union3::from0(color))
  self.active_context.fill() 
  self.active_context.restore()
}
//画圆框
pub impl @system.Backend for CanvasBackend with draw_stroke_circle(
  self,
  x~,
  y~,
  radius~,
  color~,
  line_width~,
) {
  self.active_context.save()
  self.active_context.begin_path() // 开始一条新的路径
  self.active_context.arc(x, y, radius, 0.0, 6.28318530718)
  self.active_context.set_stroke_style(@js.Union3::from0(color))
  self.active_context.set_line_width(line_width)
  self.active_context.stroke() // 用指定的颜色和宽度描边路径
  self.active_context.restore()
}
//画椭圆
pub impl @system.Backend for CanvasBackend with draw_filled_ellipse(
  self,
  x~, y~, radius_x~, radius_y~, rotation~, color~,
) {
  self.active_context.save()
  self.active_context.begin_path()
  self.active_context.ellipse(x, y, radius_x, radius_y, rotation, 0.0, 6.28318530718)
  self.active_context.set_fill_style(@js.Union3::from0(color))
  self.active_context.fill()
  self.active_context.restore()
}
//画椭圆框
pub impl @system.Backend for CanvasBackend with draw_stroke_ellipse(
  self,
  x~, y~, radius_x~, radius_y~, rotation~, color~, line_width~,
) {
  self.active_context.save()
  self.active_context.begin_path()
  self.active_context.ellipse(x, y, radius_x, radius_y, rotation, 0.0, 6.28318530718)
  self.active_context.set_stroke_style(@js.Union3::from0(color))
  self.active_context.set_line_width(line_width)
  self.active_context.stroke()
  self.active_context.restore()
}
//画方框
pub impl @system.Backend for CanvasBackend with draw_rect_outline(
  self, x~, y~, width~, height~, color~, line_width~,
) {
  self.active_context.save()
  self.active_context.set_stroke_style(@js.Union3::from0(color))
  self.active_context.set_line_width(line_width)
  self.active_context.stroke_rect(x, y, width, height)
  self.active_context.restore()
}