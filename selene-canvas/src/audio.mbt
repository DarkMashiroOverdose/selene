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
// See the License for the a specific language governing permissions and
// limitations under the License.

// 定义一个可用于 FFI 的原生 Audio 类型
// 修正点：根据编译器建议，将内部类型标记为 private
priv type Audio

// FFI 绑定，用于与 JavaScript 的 Audio API 交互
extern "js" fn Audio::new(path : String) -> Audio = "(path) => new Audio(path)"
extern "js" fn Audio::play(self : Self) -> Unit = "(self) => self.play()"
extern "js" fn Audio::pause(self : Self) -> Unit = "(self) => self.pause()"
extern "js" fn Audio::set_volume(self : Self, volume : Double) -> Unit =
  "(self, volume) => self.volume = volume"
extern "js" fn Audio::set_loop(self : Self, loop_ : Bool) -> Unit =
  "(self, loop_) => self.loop = loop_"
extern "js" fn Audio::set_currentTime(self : Self, time: Double) -> Unit =
  "(self, time) => self.currentTime = time"
extern "js" fn Audio::is_ended(self : Self) -> Bool = "(self) => self.ended"
extern "js" fn Audio::is_paused(self: Self) -> Bool = "(self) => self.paused"

// 用于存储所有正在播放的音频实例的全局 Map
let audio_instances : Map[@system.AudioHandle, Audio] = Map::new()

// 用于生成唯一 ID 的全局计数器
let next_audio_id : Ref[UInt64] = Ref::new(0)

// 为 CanvasBackend 实现新的音频接口
pub impl @system.Backend for CanvasBackend with play_audio(
  _self,
  audio_path : String,
  volume~ : Double,
  loop_~ : Bool,
) -> @system.AudioHandle {
  let audio = Audio::new(audio_path)
  audio.set_volume(volume)
  audio.set_loop(loop_)
  audio.play()

  // 修正点：使用公有的 `new` 函数来构造 AudioHandle
  let handle_value = next_audio_id.val
  let handle = @system.AudioHandle::new(handle_value)
  next_audio_id.val += 1

  audio_instances.set(handle, audio)
  handle
}

pub impl @system.Backend for CanvasBackend with stop_audio(
  _self,
  handle: @system.AudioHandle,
) -> Unit {
  if audio_instances.get(handle) is Some(audio) {
    audio.pause()
    audio.set_currentTime(0.0)
    audio_instances.remove(handle)
  }
}

pub impl @system.Backend for CanvasBackend with is_audio_playing(
  _self,
  handle: @system.AudioHandle,
) -> Bool {
  if audio_instances.get(handle) is Some(audio) {
    if audio.is_ended() {
      audio_instances.remove(handle)
      return false
    }
    return !audio.is_paused()
  }
  false
}

pub impl @system.Backend for CanvasBackend with preload_audio(
  _self,
  audio_path : String,
) -> Unit {
  Audio::new(audio_path) |> ignore
}