# 로블록스 단순 포탈 (Simple Portal)

플레이어가 포탈 A를 밟으면 포탈 B로, 포탈 B를 밟으면 포탈 A로 순간이동합니다.

---

## 파일 구성

| 파일 | 역할 |
|---|---|
| `PortalSetup.lua` | Workspace에 포탈 파트 두 개를 자동 생성 |
| `PortalScript.lua` | 터치 감지 및 텔레포트 로직 |

---

## 사용 방법

### 방법 1 — Script 두 개 모두 ServerScriptService에 추가

1. Roblox Studio를 엽니다.
2. **ServerScriptService** 안에 `Script`를 두 개 만듭니다.
3. 각 Script에 `PortalSetup.lua`, `PortalScript.lua` 내용을 붙여넣습니다.
4. 게임을 실행하면 포탈이 자동으로 생성되고 작동합니다.

### 방법 2 — 직접 파트 배치 후 PortalScript만 사용

1. Workspace에 `Part`를 두 개 배치하고 이름을 각각 **PortalA**, **PortalB** 로 지정합니다.
2. **ServerScriptService** 안에 `Script`를 만들고 `PortalScript.lua` 내용을 붙여넣습니다.
3. 게임을 실행합니다.

---

## 주요 기능

- **양방향 텔레포트**: A → B, B → A 모두 작동
- **쿨다운 시스템**: 연속 텔레포트 방지 (기본 2초)
- **Neon 시각 효과**: 파란색(A) / 주황색(B) 네온 파트
- **BillboardGui 라벨**: 포탈 이름 표시

---

## 커스터마이징

`PortalScript.lua` 상단에서 아래 값을 수정할 수 있습니다.

```lua
local COOLDOWN_TIME = 2  -- 텔레포트 후 재사용 대기 시간(초)
```

`PortalSetup.lua`에서 포탈 크기와 위치를 변경할 수 있습니다.

```lua
part.Size = Vector3.new(4, 8, 1)          -- 포탈 크기 (가로, 높이, 두께)
createPortal("PortalA", Vector3.new(0, 5, 0),  "Bright blue")   -- 포탈 A 위치
createPortal("PortalB", Vector3.new(0, 5, 50), "Bright orange") -- 포탈 B 위치
```
