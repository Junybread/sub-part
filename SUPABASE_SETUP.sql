-- ===================================================================
-- 부자재 취합 시스템 - Supabase 데이터베이스 설정 스크립트
-- ===================================================================
-- 
-- 사용 방법:
-- 1. Supabase 대시보드 → SQL Editor로 이동
-- 2. 이 전체 스크립트를 복사하여 붙여넣기
-- 3. "RUN" 버튼 클릭
-- 4. 완료 메시지 확인
--
-- ===================================================================

-- 기존 테이블이 있다면 삭제 (주의: 데이터도 함께 삭제됨)
DROP TABLE IF EXISTS etc_applications CASCADE;
DROP TABLE IF EXISTS hood_applications CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ===================================================================
-- 1. 사용자 테이블
-- ===================================================================
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  acct INTEGER DEFAULT 0,
  to_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 사용자 테이블 코멘트
COMMENT ON TABLE users IS '사용자 및 지점 정보';
COMMENT ON COLUMN users.username IS '로그인 ID (지점 ID)';
COMMENT ON COLUMN users.password IS '비밀번호 (평문 - 실제 운영시 해싱 필요)';
COMMENT ON COLUMN users.branch_name IS '지점명';
COMMENT ON COLUMN users.role IS '권한 (admin/user)';
COMMENT ON COLUMN users.acct IS '예상계정수';
COMMENT ON COLUMN users.to_count IS 'T/O 인원수';

-- ===================================================================
-- 2. 잡자재 신청 테이블
-- ===================================================================
CREATE TABLE applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  branch_id TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  year TEXT NOT NULL,
  month INTEGER NOT NULL,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT applications_unique_key UNIQUE(branch_id, year, month)
);

-- 잡자재 신청 테이블 코멘트
COMMENT ON TABLE applications IS '잡자재 신청 데이터';
COMMENT ON COLUMN applications.items IS '신청 항목 배열 (JSON)';

-- ===================================================================
-- 3. 후드 설치 부자재 테이블
-- ===================================================================
CREATE TABLE hood_applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  branch_id TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  year TEXT NOT NULL,
  month INTEGER NOT NULL,
  pb1 INTEGER DEFAULT 0,
  tape INTEGER DEFAULT 0,
  flex INTEGER DEFAULT 0,
  reducer INTEGER DEFAULT 0,
  service_bag INTEGER DEFAULT 0,
  form_tape INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT hood_applications_unique_key UNIQUE(branch_id, year, month)
);

-- 후드 부자재 테이블 코멘트
COMMENT ON TABLE hood_applications IS '후드 설치 부자재 신청 데이터';
COMMENT ON COLUMN hood_applications.pb1 IS 'PB-1 세정제 (600ml)';
COMMENT ON COLUMN hood_applications.tape IS '은박테이프';
COMMENT ON COLUMN hood_applications.flex IS '알루미늄 후렉시블(100mm×10M)';
COMMENT ON COLUMN hood_applications.reducer IS '환기자재 레듀샤(125mm-100mm)';
COMMENT ON COLUMN hood_applications.service_bag IS '서비스봉투(100EA,1묶음)';
COMMENT ON COLUMN hood_applications.form_tape IS '전기레인지 폼테이프(4EA,1SET)';

-- ===================================================================
-- 4. 기타 부자재 테이블
-- ===================================================================
CREATE TABLE etc_applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  branch_id TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  year TEXT NOT NULL,
  month INTEGER NOT NULL,
  drain_tank_remain INTEGER DEFAULT 0,
  drain_hose_remain INTEGER DEFAULT 0,
  train_remain INTEGER DEFAULT 0,
  train_request INTEGER DEFAULT 0,
  insulation_remain INTEGER DEFAULT 0,
  cp_ajs_roll INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT etc_applications_unique_key UNIQUE(branch_id, year, month)
);

-- 기타 부자재 테이블 코멘트
COMMENT ON TABLE etc_applications IS '기타 부자재 신청 데이터';
COMMENT ON COLUMN etc_applications.drain_tank_remain IS '배수통 잔여수량';
COMMENT ON COLUMN etc_applications.drain_hose_remain IS '배수호스 잔여수량';
COMMENT ON COLUMN etc_applications.train_remain IS '트레인피팅 잔여수량';
COMMENT ON COLUMN etc_applications.train_request IS '트레인피팅 요청수량';
COMMENT ON COLUMN etc_applications.insulation_remain IS '단열재 잔여수량';
COMMENT ON COLUMN etc_applications.cp_ajs_roll IS 'CP-AJS 배수호스(롤)';

-- ===================================================================
-- 5. 인덱스 생성 (성능 향상)
-- ===================================================================
CREATE INDEX idx_applications_user_id ON applications(user_id);
CREATE INDEX idx_applications_year_month ON applications(year, month);
CREATE INDEX idx_applications_branch_id ON applications(branch_id);

CREATE INDEX idx_hood_applications_user_id ON hood_applications(user_id);
CREATE INDEX idx_hood_applications_year_month ON hood_applications(year, month);
CREATE INDEX idx_hood_applications_branch_id ON hood_applications(branch_id);

CREATE INDEX idx_etc_applications_user_id ON etc_applications(user_id);
CREATE INDEX idx_etc_applications_year_month ON etc_applications(year, month);
CREATE INDEX idx_etc_applications_branch_id ON etc_applications(branch_id);

-- ===================================================================
-- 6. 트리거 함수 (updated_at 자동 업데이트)
-- ===================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_hood_applications_updated_at BEFORE UPDATE ON hood_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_etc_applications_updated_at BEFORE UPDATE ON etc_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================================================
-- 7. Row Level Security (RLS) 설정
-- ===================================================================
-- 참고: 현재는 RLS를 비활성화합니다. 
-- 실제 운영시에는 Supabase Auth와 함께 RLS를 활성화하여 보안을 강화하세요.

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE hood_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE etc_applications ENABLE ROW LEVEL SECURITY;

-- 임시로 모든 접근 허용 (anon key 사용)
CREATE POLICY "Enable all access for anon" ON users FOR ALL USING (true);
CREATE POLICY "Enable all access for anon" ON applications FOR ALL USING (true);
CREATE POLICY "Enable all access for anon" ON hood_applications FOR ALL USING (true);
CREATE POLICY "Enable all access for anon" ON etc_applications FOR ALL USING (true);

-- ===================================================================
-- 8. 기본 데이터 삽입
-- ===================================================================

-- 관리자 계정 생성
INSERT INTO users (username, password, branch_name, role, acct, to_count)
VALUES ('admin', '0000', '관리자', 'admin', 0, 0)
ON CONFLICT (username) DO NOTHING;

-- 테스트용 지점 계정 (선택사항)
INSERT INTO users (username, password, branch_name, role, acct, to_count)
VALUES 
  ('test01', '1234', '테스트지점1', 'user', 2985, 16),
  ('test02', '1234', '테스트지점2', 'user', 1500, 8)
ON CONFLICT (username) DO NOTHING;

-- ===================================================================
-- 9. 뷰 생성 (선택사항 - 보고서용)
-- ===================================================================

-- 당월 전체 신청 현황 뷰
CREATE OR REPLACE VIEW v_current_month_summary AS
SELECT 
  u.username,
  u.branch_name,
  u.role,
  u.acct,
  u.to_count,
  a.year AS app_year,
  a.month AS app_month,
  a.items AS application_items,
  h.pb1, h.tape, h.flex, h.reducer, h.service_bag, h.form_tape,
  e.drain_tank_remain, e.drain_hose_remain, e.train_remain, 
  e.train_request, e.insulation_remain, e.cp_ajs_roll
FROM users u
LEFT JOIN applications a ON u.id = a.user_id
LEFT JOIN hood_applications h ON u.id = h.user_id AND a.year = h.year AND a.month = h.month
LEFT JOIN etc_applications e ON u.id = e.user_id AND a.year = e.year AND a.month = e.month
WHERE u.role = 'user';

-- ===================================================================
-- 10. 완료 메시지
-- ===================================================================
DO $$
BEGIN
  RAISE NOTICE '===================================';
  RAISE NOTICE '✅ 데이터베이스 설정 완료!';
  RAISE NOTICE '===================================';
  RAISE NOTICE '생성된 테이블:';
  RAISE NOTICE '  - users (사용자)';
  RAISE NOTICE '  - applications (잡자재)';
  RAISE NOTICE '  - hood_applications (후드 부자재)';
  RAISE NOTICE '  - etc_applications (기타 부자재)';
  RAISE NOTICE '';
  RAISE NOTICE '기본 계정:';
  RAISE NOTICE '  - 관리자: admin / 0000';
  RAISE NOTICE '  - 테스트: test01 / 1234';
  RAISE NOTICE '  - 테스트: test02 / 1234';
  RAISE NOTICE '';
  RAISE NOTICE '다음 단계:';
  RAISE NOTICE '  1. Project Settings → API에서 키 복사';
  RAISE NOTICE '  2. supabase-config.js 파일 수정';
  RAISE NOTICE '  3. login.html로 접속하여 테스트';
  RAISE NOTICE '===================================';
END $$;
