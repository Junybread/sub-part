/**
 * Supabase 설정 파일
 * 
 * ✅ 설정 완료!
 * 프로젝트 URL과 API 키가 설정되었습니다.
 */

const SUPABASE_CONFIG = {
  url: 'https://yhuvkxuzolhpnzzbpigr.supabase.co',
  anonKey: 'sb_publishable_Ka0LELW2NrPf3q3dyO1Usg_EHYTS31K'
};

// Supabase 클라이언트 초기화
let supabase;

// 페이지 로드 시 Supabase 초기화
document.addEventListener('DOMContentLoaded', () => {
  if (typeof window.supabase !== 'undefined') {
    supabase = window.supabase.createClient(
      SUPABASE_CONFIG.url,
      SUPABASE_CONFIG.anonKey
    );
    console.log('✅ Supabase 초기화 완료');
  } else {
    console.error('❌ Supabase 라이브러리가 로드되지 않았습니다.');
    alert('시스템 초기화 중 오류가 발생했습니다. 페이지를 새로고침해주세요.');
  }
});
