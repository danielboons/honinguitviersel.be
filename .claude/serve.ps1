param(
    [int]$Port = 8934
)

$root = Split-Path -Parent $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Listening on http://localhost:$Port/"

$mime = @{
    '.html' = 'text/html'
    '.htm'  = 'text/html'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.png'  = 'image/png'
    '.gif'  = 'image/gif'
    '.css'  = 'text/css'
    '.js'   = 'application/javascript'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.heic' = 'image/heic'
    '.json' = 'application/json'
    '.webp' = 'image/webp'
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $path = [System.Uri]::UnescapeDataString($req.Url.LocalPath)
    if ($path -eq '/') { $path = '/index.html' }
    $filePath = Join-Path $root ($path.TrimStart('/'))
    $resp = $context.Response
    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $ct = $mime[$ext]
        if (-not $ct) { $ct = 'application/octet-stream' }
        $resp.ContentType = $ct
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $resp.ContentLength64 = $bytes.Length
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $resp.StatusCode = 404
    }
    $resp.OutputStream.Close()
}
