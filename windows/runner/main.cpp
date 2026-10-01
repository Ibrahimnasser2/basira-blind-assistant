#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"BASIRA AI", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Borderless fullscreen for recording the demo video.
  wchar_t fullscreen[8];
  if (::GetEnvironmentVariableW(L"BASIRA_FULLSCREEN", fullscreen, 8) > 0) {
    HWND hwnd = window.GetHandle();
    MONITORINFO info{sizeof(MONITORINFO)};
    ::GetMonitorInfo(::MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY), &info);
    const RECT& r = info.rcMonitor;
    ::SetWindowLongPtr(hwnd, GWL_STYLE, WS_POPUP | WS_VISIBLE);
    ::SetWindowPos(hwnd, HWND_TOPMOST, r.left, r.top, r.right - r.left,
                   r.bottom - r.top, SWP_FRAMECHANGED | SWP_SHOWWINDOW);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
