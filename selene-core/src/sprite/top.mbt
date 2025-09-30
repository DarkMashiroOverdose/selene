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
/// Visual element that can be rendered to the screen with depth ordering and
/// positioning.
///
/// Fields:
///
/// * `sprite_type` : The visual content of the sprite (picture, animation, or
///   text).
/// * `zindex` : Rendering order priority, where higher values render on top of
///   lower values.
/// * `visible` : Whether the sprite should be rendered to the screen.
/// * `offset` : Position offset applied relative to the entity's position.
///
/// Examples:
///
/// ```notest
/// // Create an animation sprite
/// let animation = @sprite.Animation::new([frame1, frame2])
/// let sprite = @sprite.Sprite::new_animation(animation, zindex=10)
/// sprite.visible = false // Hide the sprite
///
/// // Create a picture sprite with offset
/// let picture = @sprite.Picture::new(size, "path/to/image.png")
/// let sprite = @sprite.Sprite::new_picture(picture, zindex=5, offset=@math.Vec2D::new(10.0, 20.0))
/// inspect(sprite.zindex, content="5")
///
/// // Create a text sprite
/// let text = @sprite.Text::new("Hello World", color="red")
/// let sprite = @sprite.Sprite::new_text(text, zindex=1)
/// inspect(sprite.offset.x, content="0.0") // Default offset is zero
/// ```
///
/// 

//用于定义渲染层级的默认值,以适配无layer参数的旧版本精灵
//代码来源https://www.moonbitlang.com/assets/files/lec4-ad72a543cfc3959ebd73b9a96a3afc56.pdf
pub fn[T] get_or(opt: Option[T], default: T) -> T {
  match opt {
    Some(value) => value
    None => default
  }
}
//定义渲染层
pub enum RenderLayer {
  GameWorld //游戏世界层，会受到摄像机和后期处理影响
  UI        //UI层，不受摄像机和后期处理影响
} derive(Eq, Show)
pub fn RenderLayer::game_world() -> RenderLayer {
  GameWorld
}
pub fn RenderLayer::ui() -> RenderLayer {
  UI
}
pub(all) struct Sprite {
  sprite_type : SpriteType
  zindex : Int
  mut visible : Bool
  offset : @math.Vec2D
  layer: RenderLayer //添加渲染层级的定义
  mut transform: @math.Transform
}

///|
pub let sprites : Map[@system.Entity, Sprite] = Map::new()

///|
pub enum SpriteType {
  Picture(Picture)
  Animation(Animation, frame~ : Double)
  Text(Text)
  ColorRect(ColorRect)
  ColoredShape(ColoredShape)  //添加渲染形状的定义
  TextLayout(@system.TextLayout)
}

///|
/// Make an animation sprite with default animation and zindex.
pub fn Sprite::from_animation(
  animation : Animation,
  zindex : Int,
  offset? : @math.Vec2D = @math.Vec2D::zero(),
  layer? : RenderLayer,
) -> Sprite {
  {
    sprite_type: SpriteType::Animation(animation, frame=0),
    zindex,
    offset,
    visible: true,
    layer: get_or(layer, RenderLayer::GameWorld), //添加渲染层级的定义
    transform: @math.Transform::new(), 
  }
}

///|
pub fn Sprite::from_picture(
  picture : Picture,
  zindex : Int,
  offset? : @math.Vec2D = @math.Vec2D::zero(),
  layer? : RenderLayer,
) -> Sprite {
  { 
    sprite_type: SpriteType::Picture(picture), 
    zindex, 
    offset, 
    visible: true,
    layer: get_or(layer, RenderLayer::GameWorld), //添加渲染层级的定义
    transform: @math.Transform::new(), 
  }
}

///|
pub fn Sprite::from_text(
  text : Text,
  zindex : Int,
  offset? : @math.Vec2D = @math.Vec2D::zero(),
  layer? : RenderLayer,
) -> Sprite {
  { 
    sprite_type: SpriteType::Text(text), 
    zindex, 
    offset, 
    visible: true,
    layer: get_or(layer, RenderLayer::GameWorld), //添加渲染层级的定义
    transform: @math.Transform::new(), 
  }
}
///
pub fn Sprite::from_text_layout(
  layout: @system.TextLayout,
  zindex : Int,
  offset? : @math.Vec2D = @math.Vec2D::zero(),
  layer? : RenderLayer,
) -> Sprite {
  { 
    sprite_type: SpriteType::TextLayout(layout),
    zindex, 
    offset, 
    visible: true,
    layer: get_or(layer, RenderLayer::GameWorld), //添加渲染层级的定义
    transform: @math.Transform::new(), 
  }
}

///|
pub fn Sprite::from_color_rect(
  color_rect : ColorRect,
  zindex : Int,
  offset? : @math.Vec2D = @math.Vec2D::zero(),
  layer? : RenderLayer,
) -> Sprite {
  {
    sprite_type: SpriteType::ColorRect(color_rect),
    zindex,
    offset,
    visible: true,
    layer: get_or(layer, RenderLayer::GameWorld), //添加渲染层级的定义
    transform: @math.Transform::new(), 
  }
}
//指定绘制图案
pub fn Sprite::from_shape(
  shape: ColoredShape,
  zindex: Int,
  offset?: @math.Vec2D,
  layer?: RenderLayer,
) -> Sprite {
  {
    sprite_type: SpriteType::ColoredShape(shape),
    zindex,
    visible: true,
    offset: get_or(offset, @math.Vec2D::zero()),
    layer: get_or(layer, RenderLayer::GameWorld),
    transform: @math.Transform::new(), 
  }
}

///|
/// Renders all sprites in the game world through the provided backend, handling
/// world-space and UI-space positioning.
///
/// Parameters:
///
/// * `backend` : The rendering backend used to draw sprites to the screen.
///
/// Panics if an entity has a sprite but no position component.
///
/// 
//保存原有的渲染顺序逻辑，以便兼容旧项目
pub fn render_sprite_system(backend : &@system.Backend) -> Unit {
  let all_sprites  = sprites.to_array().filter(fn(pair) { pair.0.is_alive() })
  all_sprites .sort_by(fn(sprite1, sprite2) {
    if sprite1.1.zindex < sprite2.1.zindex {
      -1
    } else if sprite1.1.zindex > sprite2.1.zindex {
      1
    } else {
      guard @position.positions.get(sprite1.0) is Some(pos1) else { return 0 }
      guard @position.positions.get(sprite2.0) is Some(pos2) else { return 0 }
      if pos1.0[Y] < pos2.0[Y] {
        -1
      } else if pos1.0[Y] > pos2.0[Y] {
        1
      } else {
        0
      }
    }
  })
  for entry  in all_sprites  {
    let e = entry.0
    let sprite = entry.1
    guard @position.positions.get(e) is Some(pos) else { continue }
    let render_pos  = if @ui.uis.get(e) is None {
      pos.0 - @camera.get_position()
    } else {
      pos.0
    }
    let final_pos = render_pos + sprite.offset
    match sprite.sprite_type {
      SpriteType::Picture(picture) if sprite.visible =>
        render_picture(backend, picture, final_pos, sprite.transform)
      SpriteType::Animation(anime, frame~) => {
        let new_frame = render_animation(
          backend,
          anime,
          frame,
          final_pos,
          sprite.visible,
          sprite.transform,
        )
        let new_sprite_type = SpriteType::Animation(anime, frame=new_frame)
        sprites.set(e, {..sprite, sprite_type: new_sprite_type})
      }
      SpriteType::Text(text) if sprite.visible =>
        render_text(backend, text, final_pos, sprite.transform)
      SpriteType::ColorRect(color_rect) if sprite.visible =>
        render_color_rect(backend, color_rect, final_pos)
      SpriteType::ColoredShape(shape) =>
        render_colored_shape(backend, shape, final_pos, sprite.transform)
      _ => ()
    }
  }
}


// 新的渲染逻辑，分离世界层和UI层的渲染

//世界层渲染几乎不变
pub fn render_world_system(backend: &@system.Backend) -> Unit {
  
    backend.set_render_target("world")
    let world_sprites = sprites.to_array().filter(fn(pair) {
        pair.0.is_alive() && pair.1.layer == RenderLayer::GameWorld
    })
    world_sprites.sort_by(fn(sprite1, sprite2) {
      if sprite1.1.zindex < sprite2.1.zindex { -1 } 
      else if sprite1.1.zindex > sprite2.1.zindex { 1 }
      else {
        guard @position.positions.get(sprite1.0) is Some(pos1) else { return 0 }
        guard @position.positions.get(sprite2.0) is Some(pos2) else { return 0 }
        if pos1.0[Y] < pos2.0[Y] { -1 } 
        else if pos1.0[Y] > pos2.0[Y] { 1 }
        else { 0 }
      }
    })
    for pair in world_sprites {
        let e = pair.0
        let sprite = pair.1
        guard @position.positions.get(e) is Some(pos) else { continue }
        //想了想最终还是保留了世界层原有的UI偏移逻辑，毕竟有些项目可能会用到
        let render_pos = if @ui.uis.get(e) is None {
            pos.0 - @camera.get_position()
        } else {
          pos.0
        }
        
        render_sprite(backend, e, sprite, render_pos)
    }
}

//UI层渲染不受摄像机影响
pub fn render_ui_system(backend: &@system.Backend) -> Unit {

    backend.set_render_target("ui")
    let ui_sprites = sprites.to_array().filter(fn(pair) {
        pair.0.is_alive() && pair.1.layer == RenderLayer::UI
    })
    ui_sprites.sort_by_key(fn(pair) { pair.1.zindex })
    
    for pair in ui_sprites {
        let e = pair.0
        let sprite = pair.1
        guard @position.positions.get(e) is Some(pos) else { continue }

        let render_pos = if @ui.uis.get(e) is None {
          pos.0 - @camera.get_position()
        } else {
          pos.0
        }
        
        render_sprite(backend, e, sprite, render_pos)
    }
}
//通用渲染逻辑
fn render_sprite(backend: &@system.Backend, e: @system.Entity, sprite: Sprite, pos: @math.Vec2D) -> Unit {
    if !sprite.visible { return }
    let final_pos = pos + sprite.offset
    match sprite.sprite_type {
        Picture(picture) =>
            render_picture(backend, picture, final_pos, sprite.transform)
        Animation(anime, frame~) => {
            let new_frame = render_animation(backend, anime, frame, final_pos, true, sprite.transform)
            let new_sprite_type = SpriteType::Animation(anime, frame=new_frame)
            sprites.set(e, {..sprite, sprite_type: new_sprite_type})
        }
        Text(text) =>
            render_text(backend, text, final_pos, sprite.transform)
        ColorRect(color_rect) =>
            render_color_rect(backend, color_rect, final_pos)
        ColoredShape(shape) => 
            render_colored_shape(backend, shape, final_pos, sprite.transform)
        TextLayout(layout) => // 如果是新类型
            render_text_layout(backend, layout, final_pos, sprite.transform)
    }
}
