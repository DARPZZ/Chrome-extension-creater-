param (
    [string]$projectName = ""
)

# Define UTF8 without BOM encoding
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-FileUtf8NoBom {
    param (
        [string]$Path,
        [string]$Content
    )
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Create-ProjectStructure {
    param (
        [string]$root
    )
    Write-Host "Creating directories for project '$root'..."
    New-Item -ItemType Directory -Path $root -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path "$root/src" -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path "$root/webpack" -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path "$root/public" -ErrorAction SilentlyContinue | Out-Null
}

function Initialize-Npm {
    param (
        [string]$root
    )
    Write-Host "Initializing npm in '$root'..."
    Push-Location $root
    npm init -y | Out-Null
    Pop-Location
}

function Install-Dependencies {
    param (
        [string]$root
    )
    Write-Host "Installing dependencies in '$root'..."
    Push-Location $root
    npm install --save-dev webpack webpack-cli copy-webpack-plugin typescript ts-loader @types/chrome | Out-Null
    Pop-Location
}

function Create-TsConfig {
    param (
        [string]$root
    )
    $content = @"
{
   "compilerOptions": {
      "strict": false,
      "module": "commonjs",
      "target": "es6",
      "esModuleInterop": true,
      "sourceMap": true,
      "rootDir": "src",
      "outDir": "dist/js",
      "noEmitOnError": true,
      "typeRoots": [ "node_modules/@types" ]
   }
}
"@
    Write-Host "Creating tsconfig.json in '$root'..."
    Write-FileUtf8NoBom -Path "$root/tsconfig.json" -Content $content
}

function Create-WebpackConfig {
    param (
        [string]$root
    )
    $content = @"
const path = require('path');
const CopyPlugin = require('copy-webpack-plugin');
module.exports = {
   mode: "production",
   entry: {
      background: path.resolve(__dirname, "..", "src", "background.ts"),
   },
   output: {
      path: path.join(__dirname, "../dist"),
      filename: "[name].js",
   },
   resolve: {
      extensions: [".ts", ".js"],
   },
   module: {
      rules: [
         {
            test: /\.tsx?$/,
            loader: "ts-loader",
            exclude: /node_modules/,
         },
      ],
   },
   plugins: [
      new CopyPlugin({
         patterns: [{from: ".", to: ".", context: "public"}]
      }),
   ],
};
"@
    Write-Host "Creating webpack.config.js in '$root/webpack'..."
    Write-FileUtf8NoBom -Path "$root/webpack/webpack.config.js" -Content $content
}

function Create-PackageJson {
    param (
        [string]$root,
        [string]$projectName
    )
    $content = @"
{
  "name": "$projectName",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "build:v2": "cross-env MANIFEST_VERSION=2 webpack --config webpack/webpack.config.js",
    "build:v3": "cross-env MANIFEST_VERSION=3 webpack --config webpack/webpack.config.js",
    "build": "npm run build:v2 && npm run build:v3"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "webpack-cli": "^4.9.1",
    "typescript": "^4.5.4",
    "cross-env": "*",
    "webpack": "^5.66.0",
    "@types/chrome": "*",
    "ts-loader": "^9.2.6",
    "copy-webpack-plugin": "*"
  }
}
"@

    Write-FileUtf8NoBom -Path "$root/package.json" -Content $content
}

function Create-ManifestJson-v3 {
    param (
        [string]$root
    )
    $content = @"
{
   "name": "$projectName",
   "description": "This extension is made for demonstration purposes",
   "version": "1.0",
   "manifest_version": 3,
   "permissions": [
      "activeTab",
      "scripting"
   ],
   "background": {
      "service_worker": "background.js"
   }
}
"@
    Write-Host "Creating manifest.json in '$root/public'..."
    Write-FileUtf8NoBom -Path "$root/public/manifest.json" -Content $content
}


function Create-ManifestJson-v2 {
    param (
        [string]$root
    )
    $content = @"
{
   "name": "$projectName",
   "description": "This extension is made for demonstration purposes",
   "version": "1.0",
   "manifest_version": 2,
   "permissions": [
      "activeTab",
      "scripting"
   ],
   "background": {
    "scripts": ["background.js"],
    "persistent": false
  },
}
"@
    Write-Host "Creating manifest.json in '$root/public'..."
    Write-FileUtf8NoBom -Path "$root/public/manifest.json" -Content $content
}



function Create-BackgroundTs {
    param (
        [string]$root
    )
    $content = @"
console.warn("Background script is loaded")
"@
    Write-Host "Creating background.ts in '$root/src'..."
    Write-FileUtf8NoBom -Path "$root/src/background.ts" -Content $content
}

function Install-CrossEnv {
    param (
        [string]$root
    )
    Write-Host "Installing cross-env for environment variables in npm scripts in '$root'..."
    Push-Location $root
    npm install --save-dev cross-env | Out-Null
    Pop-Location
}

function Open-VSCode {
    param (
        [string]$root
    )
    Write-Host "Opening Visual Studio Code at '$root'..."
    Start-Process "code" -ArgumentList $root
}

function Main {
    param (
        [string]$projectName
    )
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        Write-Error "Project name cannot be empty."
        return
    }
    $projectDir = $projectName

    Create-ProjectStructure -root $projectDir
    Initialize-Npm -root $projectDir
    Install-Dependencies -root $projectDir
    Install-CrossEnv -root $projectDir
    Create-TsConfig -root $projectDir
    Create-WebpackConfig -root $projectDir
    Create-PackageJson -root $projectDir -projectName $projectName
    Create-ManifestJson-v3 -root $projectDir
    Create-ManifestJson-v2 -root $projectDir
    Create-BackgroundTs -root $projectDir
    Open-VSCode -root $projectDir
}

Main -projectName $projectName
