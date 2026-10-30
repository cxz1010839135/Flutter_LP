# 用 C# 读取 S 寄存器

对齐上位机 `HttpManager.getRegS`：HTTP POST JSON，命令 `robot_get_S`。

- 地址：`http://控制器IP`（无路径，默认 `http://192.168.11.11`）
- 请求：`{"command":"robot_get_S","data":{"index":地址}}`
- 成功：`result == 1`，`data` 为整型当前值（步序/状态 S）
- 控制器较旧：不要走系统代理，不要 chunked，连接用 `Connection: close`

```csharp
using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

/// <summary>
/// 读取 PLC 状态寄存器 S（与监控页「状态 S」同一接口）。
/// </summary>
public static class RobotPlcS
{
    public static async Task<int> ReadSAsync(string baseUrl, int index)
    {
        if (string.IsNullOrWhiteSpace(baseUrl))
            throw new ArgumentException("baseUrl 不能为空", nameof(baseUrl));
        if (index < 0)
            throw new ArgumentOutOfRangeException(nameof(index));

        var url = baseUrl.TrimEnd('/');
        var payload = JsonSerializer.Serialize(new
        {
            command = "robot_get_S",
            data = new { index }
        });

        using var handler = new HttpClientHandler { UseProxy = false };
        using var client = new HttpClient(handler)
        {
            Timeout = TimeSpan.FromSeconds(5)
        };
        client.DefaultRequestHeaders.ConnectionClose = true;
        client.DefaultRequestHeaders.TryAddWithoutValidation("User-Agent", "LPRobot/2.1.6");
        client.DefaultRequestHeaders.TryAddWithoutValidation("Accept", "*/*");

        using var content = new StringContent(payload, Encoding.UTF8, "application/json");
        using var response = await client.PostAsync(url, content).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
        body = body.Trim().TrimStart('\uFEFF');

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;
        var result = root.TryGetProperty("result", out var resultEl)
            ? resultEl.GetInt32()
            : 0;
        if (result != 1)
        {
            var msg = root.TryGetProperty("msg", out var msgEl)
                ? msgEl.ToString()
                : $"result={result}";
            throw new InvalidOperationException($"读取 S{index} 失败：{msg}");
        }

        var data = root.GetProperty("data");
        if (data.ValueKind == JsonValueKind.Number)
            return data.GetInt32();
        if (int.TryParse(data.ToString(), out var value))
            return value;
        throw new FormatException($"S{index} 响应 data 不是整数：{data}");
    }
}

// 示例：int s10 = await RobotPlcS.ReadSAsync("http://192.168.11.11", 10);
```

Dart 对照：`lib/network/api/robot_http_plc.dart` 中 `getRegS(addr)` → `_getReg('robot_get_S', addr)`。
