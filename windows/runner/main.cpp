#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                      _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line,
                      _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  auto desktop = GetDesktopWindow();
  RECT rect;
  GetWindowRect(desktop, &rect);
  int width = 400;
  int height = 600;
  HMONITOR monitor = MonitorFromWindow(desktop, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  Win32Window::Point origin((rect.right - width) / 2 / dpi * 96,
                            (rect.bottom - height) / 2 / dpi * 96);
  Win32Window::Size size(width, height);
  if (!window.CreateAndShow(L"vad_demo", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

// #include <cassert>
// #include "datareader.h"
// #include "net.h"

// ncnn::Net g_net;
// ncnn::Mat g_model;

// extern "C" __declspec(dllexport) int32_t load(const unsigned char* param,
//                                               int32_t len1,
//                                               const unsigned char* model,
//                                               int32_t len2) {
//   auto ret = g_net.load_param_mem((char*)param);
//   if (ret != 0) {
//     return ret;
//   }
//   g_model = ncnn::Mat(len2);
//   memcpy(g_model.data, model, len2);
//   g_net.load_model((const unsigned char*)g_model.data);
//   return ret;
// }

// extern "C" __declspec(dllexport) float run(const float* data,
//                                            int32_t len,
//                                            const float* ci,
//                                            const float* hi) {
//   auto ex = g_net.create_extractor();
//   ncnn::Mat in(len, 1, (void*)data, 4, 1);
//   ncnn::Mat c(64, 2, 1, (void*)ci, 4, 1);
//   ncnn::Mat h(64, 2, 1, (void*)hi, 4, 1);
//   ex.input("input", in);
//   ex.input("c", c);
//   ex.input("h", h);
//   ncnn::Mat out;
//   auto ret = ex.extract("output", out);
//   assert(ret == 0);
//   ncnn::Mat cn;
//   ncnn::Mat hn;
//   ret = ex.extract("cn", cn);
//   assert(ret == 0);
//   memcpy((void*)ci, cn.data, 64 * 2 * 4);
//   ret = ex.extract("hn", hn);
//   assert(ret == 0);
//   memcpy((void*)hi, hn.data, 64 * 2 * 4);
//   return *(float*)out.data;
// }
