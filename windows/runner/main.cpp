#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include <algorithm>
#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

std::wstring BuildWindowTitle() {
#if defined(FLUTTER_VERSION_MAJOR) && defined(FLUTTER_VERSION_MINOR) && \
    defined(FLUTTER_VERSION_PATCH)
  return L"\u9886\u9e4f\u667a\u80fd " +
         std::to_wstring(FLUTTER_VERSION_MAJOR) + L"." +
         std::to_wstring(FLUTTER_VERSION_MINOR) + L"." +
         std::to_wstring(FLUTTER_VERSION_PATCH);
#else
  return L"\u9886\u9e4f\u667a\u80fd";
#endif
}

double MonitorScaleFactor(HMONITOR monitor) {
  const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  return dpi / 96.0;
}

/// Fit logical window size into the monitor work area (DPI aware).
Win32Window::Size FitWindowSize(const RECT& work_area, HMONITOR monitor,
                                unsigned int logical_width,
                                unsigned int logical_height) {
  const double scale = MonitorScaleFactor(monitor);
  const int area_w = work_area.right - work_area.left;
  const int area_h = work_area.bottom - work_area.top;

  int phys_w = static_cast<int>(logical_width * scale);
  int phys_h = static_cast<int>(logical_height * scale);
  phys_w = std::min(phys_w, area_w);
  phys_h = std::min(phys_h, area_h);

  const unsigned int fitted_w =
      std::max(1u, static_cast<unsigned int>(phys_w / scale));
  const unsigned int fitted_h =
      std::max(1u, static_cast<unsigned int>(phys_h / scale));
  return Win32Window::Size(fitted_w, fitted_h);
}

Win32Window::Point CenterWindowOrigin(const RECT& work_area, HMONITOR monitor,
                                      const Win32Window::Size& size) {
  const double scale = MonitorScaleFactor(monitor);
  const int area_w = work_area.right - work_area.left;
  const int area_h = work_area.bottom - work_area.top;
  const int phys_w = static_cast<int>(size.width * scale);
  const int phys_h = static_cast<int>(size.height * scale);

  const int phys_x = work_area.left + (area_w - phys_w) / 2;
  const int phys_y = work_area.top + (area_h - phys_h) / 2;

  const unsigned int logical_x = static_cast<unsigned int>(phys_x / scale);
  const unsigned int logical_y = static_cast<unsigned int>(phys_y / scale);
  return Win32Window::Point(logical_x, logical_y);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {  // Attach to console when present (e.g., 'flutter run') or create a
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
  Win32Window::Size size(1280, 720);
  RECT work_area{};
  SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const POINT center_point = {
      work_area.left + (work_area.right - work_area.left) / 2,
      work_area.top + (work_area.bottom - work_area.top) / 2,
  };
  HMONITOR monitor =
      MonitorFromPoint(center_point, MONITOR_DEFAULTTONEAREST);
  size = FitWindowSize(work_area, monitor, size.width, size.height);
  Win32Window::Point origin = CenterWindowOrigin(work_area, monitor, size);
  if (!window.Create(BuildWindowTitle().c_str(), origin, size)) {
    return EXIT_FAILURE;
  }
  window.Show();
  if (HWND hwnd = window.GetHandle()) {
    SetForegroundWindow(hwnd);
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
