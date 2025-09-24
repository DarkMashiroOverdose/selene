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

// --- 类型别名和公共 API ---

///|
/// 为上层代码提供一个简洁的类型别名，
/// 以便可以通过 `@audio.AudioHandle` 访问。
///
pub typealias @system.AudioHandle as AudioHandle

///|
/// 通过指定的后端播放音频文件，并返回一个可用于控制该音频实例的句柄。
///
/// Parameters:
///
/// * `backend` : 用于播放音频的后端。
/// * `audio_path` : 要播放的音频文件的路径。
/// * `volume` : 播放音量，默认为 1.0。
/// * `loop_` : 是否循环播放，默认为 false。
///
/// Returns:
///
/// 一个 `AudioHandle`，可用于之后停止或查询该声音的状态。
///
pub fn play_audio(
  backend : &@system.Backend,
  audio_path : String,
  volume? : Double = 1.0,
  loop_? : Bool = false,
) -> AudioHandle {
  backend.play_audio(audio_path, volume~, loop_~)
}

///|
/// 使用句柄停止一个正在播放的音频实例。
/// 如果音频已播放完毕或句柄无效，此函数不执行任何操作。
///
/// Parameters:
///
/// * `backend` : 音频后端。
/// * `handle` : 从 `play_audio` 返回的 `AudioHandle`。
///
pub fn stop_audio(backend: &@system.Backend, handle: AudioHandle) -> Unit {
  backend.stop_audio(handle)
}

///|
/// 使用句柄检查一个音频实例当前是否仍在播放。
///
/// Parameters:
///
/// * `backend` : 音频后端。
/// * `handle` : 从 `play_audio` 返回的 `AudioHandle`。
///
/// Returns:
///
/// 如果声音正在播放，则为 `true`；如果声音已停止、已播放完毕或句柄无效，则为 `false`。
///
pub fn is_audio_playing(backend: &@system.Backend, handle: AudioHandle) -> Bool {
  backend.is_audio_playing(handle)
}

