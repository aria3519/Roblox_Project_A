-- MonsterSystem/MonsterStats.lua
-- ModuleScript: 몬스터 종류별 스텟 정의
-- 새 몬스터 추가 시 이 파일에만 항목을 추가하면 됩니다.

local MonsterStats = {}

-- ==============================
-- 몬스터 스텟 테이블
-- ==============================
-- Health        : 최대 체력
-- Damage        : 공격 데미지
-- Speed         : 이동 속도 (기본 16)
-- AttackRange   : 공격 사정거리 (스터드)
-- AttackCooldown: 공격 쿨다운 (초)
-- DetectRange   : 플레이어 감지 거리 (스터드)
-- Color         : 몸통 색상 (BrickColor 이름)
-- ==============================

MonsterStats.Types = {

	Goblin = {
		Health         = 50,
		Damage         = 8,
		Speed          = 14,
		AttackRange    = 4,
		AttackCooldown = 1.5,
		DetectRange    = 30,
		Color          = "Bright green",
	},

	Orc = {
		Health         = 150,
		Damage         = 20,
		Speed          = 10,
		AttackRange    = 5,
		AttackCooldown = 2.0,
		DetectRange    = 25,
		Color          = "Dark green",
	},

	Skeleton = {
		Health         = 80,
		Damage         = 12,
		Speed          = 12,
		AttackRange    = 4,
		AttackCooldown = 1.2,
		DetectRange    = 35,
		Color          = "White",
	},

	Troll = {
		Health         = 300,
		Damage         = 35,
		Speed          = 8,
		AttackRange    = 6,
		AttackCooldown = 3.0,
		DetectRange    = 20,
		Color          = "Reddish brown",
	},

	Dragon = {
		Health         = 500,
		Damage         = 50,
		Speed          = 12,
		AttackRange    = 8,
		AttackCooldown = 2.5,
		DetectRange    = 50,
		Color          = "Bright red",
	},

}

-- 몬스터 타입 유효성 검사
function MonsterStats.Get(monsterType)
	local stats = MonsterStats.Types[monsterType]
	if not stats then
		warn("[MonsterStats] 알 수 없는 몬스터 타입: " .. tostring(monsterType))
		return nil
	end
	-- 복사본 반환 (원본 수정 방지)
	local copy = {}
	for k, v in pairs(stats) do copy[k] = v end
	return copy
end

return MonsterStats
