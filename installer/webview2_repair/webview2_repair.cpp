#include <windows.h>
#include <aclapi.h>

#include <array>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

namespace {

std::wstring ReadEnvironment(const wchar_t* name) {
  const DWORD required = GetEnvironmentVariableW(name, nullptr, 0);
  if (required == 0) {
    return {};
  }

  std::vector<wchar_t> buffer(required);
  const DWORD written =
      GetEnvironmentVariableW(name, buffer.data(), static_cast<DWORD>(buffer.size()));
  if (written == 0 || written >= buffer.size()) {
    return {};
  }
  return std::wstring(buffer.data(), written);
}

std::wstring JoinPath(const std::wstring& left, const wchar_t* right) {
  if (left.empty()) {
    return {};
  }
  const wchar_t separator = left.back() == L'\\' ? L'\0' : L'\\';
  return separator == L'\0' ? left + right : left + separator + right;
}

bool EnablePrivilege(HANDLE token, const wchar_t* privilegeName) {
  TOKEN_PRIVILEGES privileges{};
  privileges.PrivilegeCount = 1;
  privileges.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
  if (LookupPrivilegeValueW(nullptr, privilegeName,
                            &privileges.Privileges[0].Luid) == FALSE) {
    return false;
  }

  SetLastError(ERROR_SUCCESS);
  if (AdjustTokenPrivileges(token, FALSE, &privileges, 0, nullptr, nullptr) ==
      FALSE) {
    return false;
  }
  return GetLastError() == ERROR_SUCCESS;
}

bool TakeOwnershipAndGrantFullAccess(const std::wstring& path) {
  HANDLE token = nullptr;
  if (OpenProcessToken(GetCurrentProcess(),
                       TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &token) == FALSE) {
    return false;
  }

  EnablePrivilege(token, SE_TAKE_OWNERSHIP_NAME);
  EnablePrivilege(token, SE_RESTORE_NAME);

  DWORD required = 0;
  GetTokenInformation(token, TokenUser, nullptr, 0, &required);
  if (required == 0) {
    CloseHandle(token);
    return false;
  }

  std::vector<BYTE> tokenInfo(required);
  if (GetTokenInformation(token, TokenUser, tokenInfo.data(), required,
                          &required) == FALSE) {
    CloseHandle(token);
    return false;
  }
  CloseHandle(token);

  const auto* tokenUser =
      reinterpret_cast<const TOKEN_USER*>(tokenInfo.data());
  PSID userSid = tokenUser->User.Sid;
  wchar_t* mutablePath = const_cast<wchar_t*>(path.c_str());
  if (SetNamedSecurityInfoW(mutablePath, SE_FILE_OBJECT,
                            OWNER_SECURITY_INFORMATION, userSid, nullptr,
                            nullptr, nullptr) != ERROR_SUCCESS) {
    return false;
  }

  EXPLICIT_ACCESSW access{};
  access.grfAccessPermissions = GENERIC_ALL;
  access.grfAccessMode = SET_ACCESS;
  access.grfInheritance = NO_INHERITANCE;
  access.Trustee.TrusteeForm = TRUSTEE_IS_SID;
  access.Trustee.TrusteeType = TRUSTEE_IS_USER;
  access.Trustee.ptstrName = static_cast<wchar_t*>(userSid);

  PACL newAcl = nullptr;
  const DWORD aclResult = SetEntriesInAclW(1, &access, nullptr, &newAcl);
  if (aclResult != ERROR_SUCCESS) {
    return false;
  }

  const DWORD securityResult =
      SetNamedSecurityInfoW(mutablePath, SE_FILE_OBJECT,
                            DACL_SECURITY_INFORMATION |
                                PROTECTED_DACL_SECURITY_INFORMATION,
                            nullptr, nullptr, newAcl, nullptr);
  LocalFree(newAcl);
  return securityResult == ERROR_SUCCESS;
}

bool DeleteOrQuarantine(const std::wstring& path) {
  SetFileAttributesW(path.c_str(), FILE_ATTRIBUTE_NORMAL);
  if (DeleteFileW(path.c_str()) != FALSE) {
    return true;
  }

  const std::wstring quarantinePath = path + L".lpzn-invalid";
  SetFileAttributesW(quarantinePath.c_str(), FILE_ATTRIBUTE_NORMAL);
  DeleteFileW(quarantinePath.c_str());
  if (MoveFileExW(path.c_str(), quarantinePath.c_str(),
                  MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) == FALSE) {
    return false;
  }

  MoveFileExW(quarantinePath.c_str(), nullptr, MOVEFILE_DELAY_UNTIL_REBOOT);
  return true;
}

bool RemoveCollisionFile(const std::wstring& path) {
  const DWORD attributes = GetFileAttributesW(path.c_str());
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    return GetLastError() == ERROR_FILE_NOT_FOUND ||
           GetLastError() == ERROR_PATH_NOT_FOUND;
  }

  // 正常目录属于 Edge/WebView2，绝不能删除；这里只处理阻塞建目录的同名文件。
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return true;
  }

  if (DeleteOrQuarantine(path)) {
    std::wcout << L"Removed WebView2 collision file: " << path << std::endl;
    return true;
  }

  // 异常文件可能带有拒绝访问 ACL。安装程序已提升权限，仅对该文件
  // 取得所有权并授予当前管理员完全控制，然后再次尝试清理。
  if (TakeOwnershipAndGrantFullAccess(path) && DeleteOrQuarantine(path)) {
    std::wcout << L"Repaired protected WebView2 collision file: " << path
               << std::endl;
    return true;
  }

  const DWORD error = GetLastError();
  std::wcerr << L"Unable to remove WebView2 collision file: " << path
             << L" (Win32 error " << error << L")" << std::endl;
  return false;
}

}  // namespace

int wmain() {
  const std::array<std::wstring, 2> roots = {
      JoinPath(ReadEnvironment(L"ProgramFiles(x86)"), L"Microsoft"),
      JoinPath(ReadEnvironment(L"ProgramFiles"), L"Microsoft"),
  };
  constexpr std::array<const wchar_t*, 3> collisionNames = {
      L"EdgeUpdate",
      L"EdgeWebView",
      L"Temp",
  };

  bool success = true;
  for (const std::wstring& root : roots) {
    if (root.empty()) {
      continue;
    }
    for (const wchar_t* name : collisionNames) {
      success = RemoveCollisionFile(JoinPath(root, name)) && success;
    }
  }

  return success ? 0 : ERROR_ACCESS_DENIED;
}
