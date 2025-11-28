# Computer Graphics - Lab 3

## 完成項目

### 基礎功能 (100%)

| 功能                                       | 狀態    |
| ------------------------------------------ | ------- |
| 1. Rotation Matrix (Y-axis) -`makeRotY`  | ✅ 完成 |
| 2. Rotation Matrix (X-axis) -`makeRotX`  | ✅ 完成 |
| 3. Model Matrix -`localToWorld`          | ✅ 完成 |
| 4. View Matrix -`setPositionOrientation` | ✅ 完成 |
| 5. Projection Matrix -`setSize`          | ✅ 完成 |
| 6. Depth Buffer -`getDepth`              | ✅ 完成 |
| 7. Camera Control -`cameraControl`       | ✅ 完成 |
| 8. Backface Culling -`debugDraw`         | ✅ 完成 |

### Bonus 功能

| 功能        | 狀態    |
| ----------- | ------- |
| 3D Clipping | ✅ 完成 |

---

## 作品截圖

### Debug 模式 (Wireframe)
![Debug Mode](Wireframe.gif)

Debug 模式顯示物體的線框結構，可以看到 backface culling 正確剔除了背面的線條。

### 實心渲染模式 (Solid)
![Solid Mode](Solid.gif)

實心渲染模式使用 depth buffer 正確處理遮擋關係，物體填充為黑色。

---

## 實作說明

### 1. Rotation Matrices (`Matrix4.pde`)

#### makeRotX - X軸旋轉矩陣 (Pitch)

```java
void makeRotX(float a) {
    // | 1    0       0    0 |
    // | 0  cos(a) -sin(a) 0 |
    // | 0  sin(a)  cos(a) 0 |
    // | 0    0       0    1 |
    m[0]  = 1.0f;   m[1]  = 0.0f;    m[2]  = 0.0f;    m[3]  = 0.0f;
    m[4]  = 0.0f;   m[5]  = cos(a);  m[6]  = -sin(a); m[7]  = 0.0f;
    m[8]  = 0.0f;   m[9]  = sin(a);  m[10] = cos(a);  m[11] = 0.0f;
    m[12] = 0.0f;   m[13] = 0.0f;    m[14] = 0.0f;    m[15] = 1.0f;
}
```

#### makeRotY - Y軸旋轉矩陣 (Yaw)

```java
void makeRotY(float a) {
    // | cos(a)  0  sin(a)  0 |
    // |   0     1    0     0 |
    // |-sin(a)  0  cos(a)  0 |
    // |   0     0    0     1 |
    m[0]  = cos(a);  m[1]  = 0.0f;  m[2]  = sin(a);  m[3]  = 0.0f;
    m[4]  = 0.0f;    m[5]  = 1.0f;  m[6]  = 0.0f;    m[7]  = 0.0f;
    m[8]  = -sin(a); m[9]  = 0.0f;  m[10] = cos(a);  m[11] = 0.0f;
    m[12] = 0.0f;    m[13] = 0.0f;  m[14] = 0.0f;    m[15] = 1.0f;
}
```

**旋轉矩陣對應關係：**

- **Yaw (偏航)**: Y軸旋轉 - 左右轉頭
- **Pitch (俯仰)**: X軸旋轉 - 上下點頭
- **Roll (翻滾)**: Z軸旋轉 - 側向傾斜

---

### 2. Model Matrix (`GameObject.pde`)

```java
Matrix4 localToWorld() {
    // Model Matrix = Translation * RotationY * RotationX * RotationZ * Scale
    Matrix4 translationMatrix = Matrix4.Trans(transform.position);
    Matrix4 rotationY = Matrix4.RotY(transform.rotation.y);
    Matrix4 rotationX = Matrix4.RotX(transform.rotation.x);
    Matrix4 rotationZ = Matrix4.RotZ(transform.rotation.z);
    Matrix4 scaleMatrix = Matrix4.Scale(transform.scale);
  
    // 變換順序：Scale -> RotZ -> RotX -> RotY -> Translate
    Matrix4 modelMatrix = translationMatrix.mult(rotationY).mult(rotationX).mult(rotationZ).mult(scaleMatrix);
    return modelMatrix;
}
```

**說明：** Model Matrix 將物體從局部座標系轉換到世界座標系。變換順序由右至左執行：先縮放、再旋轉、最後平移。

---

### 3. View Matrix (`Camera.pde`)

使用 **LookAt 演算法** 建構視圖矩陣：

```java
void setPositionOrientation(Vector3 pos, Vector3 lookat) {
    Vector3 up = new Vector3(0, 1, 0);
  
    // 計算相機座標系的三個軸
    Vector3 forward = Vector3.sub(lookat, pos).unit_vector();
    Vector3 right = Vector3.cross(forward, up).unit_vector();
    Vector3 newUp = Vector3.cross(right, forward).unit_vector();
  
    // 建構視圖矩陣
    worldView.m[0] = right.x;    worldView.m[1] = right.y;    worldView.m[2] = right.z;
    worldView.m[3] = -Vector3.dot(right, pos);
  
    worldView.m[4] = newUp.x;    worldView.m[5] = newUp.y;    worldView.m[6] = newUp.z;
    worldView.m[7] = -Vector3.dot(newUp, pos);
  
    worldView.m[8] = forward.x;  worldView.m[9] = forward.y;  worldView.m[10] = forward.z;
    worldView.m[11] = -Vector3.dot(forward, pos);
  
    worldView.m[15] = 1;
}
```

**說明：** View Matrix 將世界座標轉換到相機座標系。使用 forward、right、up 三個正交向量建構旋轉部分，並計算相機位置的投影作為平移部分。

---

### 4. Projection Matrix (`Camera.pde`)

使用 **透視投影矩陣**：

```java
void setSize(int w, int h, float n, float f) {
    float aspect = (float)w / (float)h;
    float fovRad = radians(GH_FOV);  // FOV = 45°
    float tanHalfFov = tan(fovRad / 2.0);
  
    projection.makeZero();
    projection.m[0] = 1.0 / (aspect * tanHalfFov);
    projection.m[5] = 1.0 / tanHalfFov;
    projection.m[10] = (f + n) / (f - n);
    projection.m[11] = -2.0 * f * n / (f - n);
    projection.m[14] = 1.0;
}
```

**說明：** 透視投影矩陣將 3D 座標投影到 2D 螢幕，產生近大遠小的效果。使用 FOV（視野角）、長寬比、近平面和遠平面來定義視錐體。

---

### 5. Depth Buffer (`util.pde`)

使用 **重心座標插值** 計算深度：

```java
public float getDepth(float x, float y, Vector3[] vertex) {
    Vector3 A = vertex[0], B = vertex[1], C = vertex[2];
  
    // 計算重心座標 (u, v, w)
    float denominator = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    float u = ((B.y - C.y) * (x - C.x) + (C.x - B.x) * (y - C.y)) / denominator;
    float v = ((C.y - A.y) * (x - C.x) + (A.x - C.x) * (y - C.y)) / denominator;
    float w = 1.0 - u - v;
  
    // 插值計算 z 值
    float z = u * A.z + v * B.z + w * C.z;
    return z;
}
```

**說明：** 使用重心座標公式 $P = uA + vB + wC$（其中 $u + v + w = 1$）來插值計算三角形內任意點的深度值。

---

### 6. Camera Control (`HW3.pde`)

實作 **軌道相機 (Orbit Camera)**：

```java
void cameraControl(){
    // 使用球座標系統
    Vector3 offset = Vector3.sub(cam_position, lookat);
    float radius = offset.length();
    float theta = atan2(offset.x, offset.z);  // 水平角
    float phi = asin(offset.y / radius);       // 垂直角
  
    // WASD: 繞物體旋轉
    if (key == 'a') theta += orbitSpeed;
    if (key == 'd') theta -= orbitSpeed;
    if (key == 'w') phi = constrain(phi + orbitSpeed, -HALF_PI + 0.1, HALF_PI - 0.1);
    if (key == 's') phi = constrain(phi - orbitSpeed, -HALF_PI + 0.1, HALF_PI - 0.1);
  
    // 更新相機位置（球座標轉直角座標）
    cam_position.x = lookat.x + radius * cos(phi) * sin(theta);
    cam_position.y = lookat.y + radius * sin(phi);
    cam_position.z = lookat.z + radius * cos(phi) * cos(theta);
}
```

**控制方式：**

| 按鍵   | 功能             |
| ------ | ---------------- |
| W/S    | 上下繞物體旋轉   |
| A/D    | 左右繞物體旋轉   |
| Q/E    | 拉近/拉遠 (Zoom) |
| 方向鍵 | 平移視點 (Pan)   |

---

### 7. Backface Culling (`GameObject.pde`)

使用 **2D 有向面積** 判斷面的朝向：

```java
// 計算螢幕空間的有向面積
Vector3 edge1 = Vector3.sub(s_Position[1], s_Position[0]);
Vector3 edge2 = Vector3.sub(s_Position[2], s_Position[0]);
float signedArea = edge1.x * edge2.y - edge1.y * edge2.x;

// 負值表示背面，跳過不渲染
if (signedArea < 0) continue;
```

**說明：** 在螢幕空間中，使用叉積計算三角形的有向面積。如果面積為負，表示三角形的頂點是順時針排列（背對相機），應該被剔除。

---

### 8. Bonus: 3D Clipping (`GameObject.pde`)

實作兩階段裁切：

#### 階段一：近平面裁切

```java
// 在 clip space 裁切，使用 w 值判斷
float epsilon = 0.001;
boolean v0_inside = v0.w > epsilon;
boolean v1_inside = v1.w > epsilon;

if (!v0_inside) {
    float t = (epsilon - v0.w) / (v1.w - v0.w);
    clipped_v0 = lerp(v0, v1, t);  // 線性插值
}
```

#### 階段二：NDC 立方體裁切（Liang-Barsky 演算法）

```java
float[] clipLineToFrustum(float x0, float y0, float z0, float x1, float y1, float z1) {
    float t0 = 0.0, t1 = 1.0;
    float[] p = {-dx, dx, -dy, dy, -dz, dz};
    float[] q = {x0+1, 1-x0, y0+1, 1-y0, z0+1, 1-z0};
  
    for (int i = 0; i < 6; i++) {
        float t = q[i] / p[i];
        if (p[i] < 0) t0 = max(t0, t);  // 進入平面
        else t1 = min(t1, t);            // 離開平面
    }
  
    if (t0 > t1) return null;  // 完全在外面
    // 計算裁切後的端點...
}
```

**說明：**

1. **近平面裁切**：在 clip space（齊次座標除法之前）對 w > 0 進行裁切，避免除以零的問題
2. **NDC 裁切**：使用 Liang-Barsky 演算法對 NDC 立方體 [-1, 1] 的六個面進行線段裁切

---

## 使用的演算法總結

| 演算法                    | 用途             |
| ------------------------- | ---------------- |
| LookAt Matrix             | 建構視圖矩陣     |
| Perspective Projection    | 透視投影         |
| Barycentric Interpolation | 深度插值         |
| Ray Casting (pnpoly)      | 點是否在多邊形內 |
| 2D Signed Area            | 背面剔除         |
| Liang-Barsky              | 3D 線段裁切      |

---

## LLM 使用說明

本作業在開發過程中使用了 **Claude** 作為輔助工具：

1. **協助理解概念**：解釋 LookAt 矩陣、透視投影矩陣的數學原理
2. **Debug 協助**：幫助分析渲染管線中的問題（如 Z-fighting、backface culling 方向）
3. **程式碼優化**：建議使用像素中心採樣來避免邊緣偽影
4. **演算法實作**：協助實作 Liang-Barsky 3D 裁切演算法


---

## 心得

透過這次作業，深入了解了 3D 渲染管線的各個階段：

1. **Model Matrix**：物體的局部座標 → 世界座標
2. **View Matrix**：世界座標 → 相機座標
3. **Projection Matrix**：相機座標 → 裁切座標（透視除法前）
4. **Perspective Division**：裁切座標 → NDC（標準化設備座標）
5. **Viewport Transform**：NDC → 螢幕座標

特別是在實作 3D Clipping 時，理解了為什麼要在齊次座標除法之前進行近平面裁切，以及 Liang-Barsky 演算法如何高效地對線段進行六面裁切。
