# Architecture Analysis

## Project Overview
本專案以 Processing/Java 實作 software rasterization pipeline，從 3D model 到螢幕像素，完整模擬現代 graphics API 的運作流程。架構模組化，分工明確，便於擴充與維護。

## Core Architecture

### 1. Rendering Pipeline Flow
```
3D Model (Mesh)
    ↓
Transform (World Space)
    ↓
Camera (View Space)
    ↓
Projection (Clip Space)
    ↓
Vertex Shader
    ↓
Rasterization + Barycentric Interpolation
    ↓
Fragment Shader
    ↓
Z-Buffer Test
    ↓
Frame Buffer (Screen)
```

### 2. GameObject System
- GameObject：場景物件基底
- Transform：位置、旋轉、縮放
- Mesh：幾何資料（vertices, normals, UVs）
- Material：shader 與 rendering properties
- Camera：view 與 projection matrix
- Light：light properties（position, color, intensity）

**設計重點**：Camera 與 Light 都繼承自 GameObject，Inspector/Hierarchy UI 可統一操作所有物件。

### 3. Material-Shader System
採用 Strategy Pattern，每種 Material 封裝自己的 vertex/fragment shader，切換材質不需改動 rendering pipeline。

已實作 Material：
- DepthMaterial
- PhongMaterial
- FlatMaterial
- GouraudMaterial
- TextureMaterial

### 4. Renderer 架構
Renderer 負責 rasterization 與 depth test：
- frameBuffer：螢幕像素
- zBuffer：深度排序
- renderGameObject()：負責座標轉換、光柵化、著色、深度測試

**實作重點**：
- Z-Buffer 保證正確遮擋
- Barycentric interpolation，確保顏色/UV平滑過渡
- Perspective correction，避免貼圖扭曲

### 5. UI System
UI 分三大區塊：
- Inspector：編輯選中物件屬性，根據型別動態顯示
- Hierarchy：場景物件列表，點選可切換編輯
- Engine：全域控制（材質切換、光源管理等）
