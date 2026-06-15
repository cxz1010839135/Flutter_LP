#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

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

}  // namespace

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
  Win32Window::Size size(1280, 720);
  RECT work_area{};
  SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const int screen_w = work_area.right - work_area.left;
  const int screen_h = work_area.bottom - work_area.top;
  int origin_x = work_area.left + (screen_w - size.width) / 2;
  int origin_y = work_area.top + (screen_h - size.height) / 2;
  if (origin_x < work_area.left) {
    origin_x = work_area.left;
  }
  if (origin_y < work_area.top) {
    origin_y = work_area.top;
  }
  Win32Window::Point origin(origin_x, origin_y);
  if (!window.Create(BuildWindowTitle().c_str(), origin, size)) {
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
