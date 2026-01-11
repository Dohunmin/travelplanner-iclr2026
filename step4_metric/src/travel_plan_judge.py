"""
LLM-as-a-Judge for Travel Plan Comparison
==========================================
LangChain 기반의 여행 계획 비교 심판 시스템 (Structured Output 사용)

Usage Example
-------------
```python
from src.travel_plan_judge import judge_travel_plans, TravelPlan

# Plan A 정의
plan_a = TravelPlan(
    schedule=\"\"\"
    1. 09:00 - 호텔 출발
    2. 09:30 - 경복궁 도착 및 관람 (2시간)
    3. 11:30 - 북촌 한옥마을 산책 (1시간)
    4. 12:30 - 삼청동 점심 식사
    5. 14:00 - 인사동 쇼핑 및 문화체험 (2시간)
    \"\"\",
    willingness=\"\"\"
    - Alice (역사 선호): 만족도 9/10
    - Bob (쇼핑 선호): 만족도 8/10
    - Carol (자연 선호): 만족도 6/10
    \"\"\",
    process=\"\"\"
    협상 과정:
    1. Alice가 경복궁 2시간 요청 → 전원 동의
    2. Bob이 명동 쇼핑 3시간 요청 → Carol 반대로 2시간으로 조정
    최종적으로 모든 구성원의 핵심 요구사항을 반영한 절충안 도출
    \"\"\",
    fpr=\"\"\"
    Pre-defined FPR:
    - 이동 시간 최소화: 충족
    - 식사 시간 확보: 충족
    Personal FPR:
    - Alice: 문화재 방문 필수 → 충족
    - Bob: 쇼핑 시간 2시간 이상 → 충족
    \"\"\"
)

# Plan B 정의 (동일 포맷)
plan_b = TravelPlan(
    schedule="...",
    willingness="...",
    process="Willingness 극대화를 최우선으로 하였습니다",  # Rule-base인 경우
    fpr="..."
)

# 심판 실행
result = judge_travel_plans(plan_a, plan_b)
print(f"Winner: {result.winner}")  # "A" or "B"
```

Judge Model Selection Guide (Based on 2024-2025 Top-tier Research)
------------------------------------------------------------------

### OpenAI 현재 모델 라인업 (2025년 1월 기준)

| 모델 | Context | Input ($/1M) | Output ($/1M) | 특징 |
|------|---------|--------------|---------------|------|
| gpt-4.1 | 1M | $2.00 | $8.00 | 가장 스마트한 non-reasoning 모델 |
| gpt-4.1-mini | 1M | ~$0.40 | ~$1.60 | instruction following 우수, 저비용 |
| gpt-4.1-nano | 1M | $0.02 | $0.15 | 초저비용, 분류/간단한 태스크 |
| gpt-4o | 128K | $2.50 | $10.00 | 멀티모달, 음성 지원 |
| gpt-4o-mini | 128K | $0.15 | $0.60 | 가장 저렴한 기존 모델 |
| gpt-5 | - | higher | higher | 복잡한 태스크용 (OpenAI 권장) |
| gpt-5-mini | - | - | - | gpt-4.1-mini보다 복잡한 태스크용 |

### 선행 연구 기반 권장사항

**1. GPT-4 계열이 여전히 표준 (Zheng et al., NeurIPS 2024 - MT-Bench)**
- GPT-4는 인간 평가자와 80% 이상 일치율 달성
- 이는 인간 평가자 간 일치율(81%)과 동등한 수준

**2. Fine-tuned Judge vs. GPT-4 (ACL Findings 2025)**
- "An Empirical Study of LLM-as-a-Judge for LLM Evaluation" 논문에서:
- Fine-tuned judge 모델(JudgeLM, Prometheus 등)은 in-domain에서 높은 성능
- 그러나 GPT-4는 generalizability, fairness, aspect-specific evaluation에서 우위
- Fine-tuned 모델은 LLMBar(fairness 벤치마크)에서 random guess보다 낮은 성능

**3. Pairwise Comparison 권장 (EMNLP 2025)**
- "From Generation to Judgment" (Li et al., EMNLP 2025) survey:
- Pairwise selection이 pointwise grading보다 안정적
- Binary output이 세분화된 점수보다 일관성 높음

**4. Position Bias 주의 (Hwang et al., EMNLP Findings 2025)**
- "Can You Trick the Grader? Adversarial Persuasion of LLM Judges":
- 모델 크기 증가가 bias 완화에 효과 미미
- 본 코드는 고정 순서(A→B) 사용, 필요시 swap augmentation 권장

**5. 비용 최적화 전략**
- 학술 논문용: `gpt-4.1` 또는 `gpt-4o` (신뢰성 + 재현성)
- 대규모 평가 + 비용 민감: `gpt-4.1-mini` (GPT-4o 대비 83% 비용 절감)
- 초저비용 + 간단한 비교: `gpt-4.1-nano` ($0.02/1M input)

### ICLR Workshop 권장 설정

학술 논문의 경우 재현성과 신뢰성이 중요하므로:
1. **Primary**: `gpt-4.1` - 가장 스마트한 non-reasoning 모델
2. **Budget-friendly**: `gpt-4.1-mini` - GPT-4o급 성능, 83% 저렴
3. **Baseline 비교시**: Human evaluation과 함께 Cohen's κ 보고 권장

References
----------
- Zheng et al. (2024) "Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena" NeurIPS
- Li et al. (2025) "From Generation to Judgment: Opportunities and Challenges of LLM-as-a-judge" EMNLP
- Zhu et al. (2025) "JudgeLM: Fine-tuned Large Language Models are Scalable Judges" ICLR Spotlight
- Kim et al. (2024) "Prometheus: Inducing Fine-grained Evaluation Capability" ICLR
- Hwang et al. (2025) "Can You Trick the Grader? Adversarial Persuasion of LLM Judges" EMNLP Findings
- ACL Findings 2025: "An Empirical Study of LLM-as-a-Judge for LLM Evaluation"

Dependencies
------------
pip install langchain langchain-openai pydantic

Environment Variables
---------------------
export OPENAI_API_KEY="your-api-key"
"""

import os
from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate


# ============================================================
# Data Models
# ============================================================

class Winner(str, Enum):
    """심판 결과 Enum - Structured Output용"""
    A = "A"
    B = "B"


class TravelPlan(BaseModel):
    """여행 계획 입력 포맷"""
    schedule: str = Field(..., description="일정 리스트")
    willingness: str = Field(..., description="페르소나별 선호도 점수 설문조사 결과 리스트")
    process: str = Field(..., description="MAD 과정 요약본 (Rule-base인 경우 'Willingness 극대화를 최우선으로 하였습니다'로 고정)")
    fpr: str = Field(..., description="FPR 리스트 (pre-defined & personal)")


class JudgeResult(BaseModel):
    """심판 결과 모델 - Winner Only (비용 절감)"""
    winner: Winner = Field(..., description="승자: A 또는 B")


# ============================================================
# System Prompt & Instructions
# ============================================================

SYSTEM_PROMPT = """You are a judge evaluating two travel plans (Plan A vs. Plan B).
Your goal is to choose the best plan based on the user's experience.

Step-by-step Evaluation:
1. **Feasibility Check:** 
   - Does any plan have fatal errors (e.g., closed venue)? 
   - Note: Ignore minor errors if the overall logic is sound.

2. **Satisfaction Check:** 
   - Which plan seems to satisfy the agents' preferences better?
   - Look for fairness and total happiness.

3. **Process Check (Important):** 
   - Which plan shows better "Conflict Resolution"? 
   - A plan that explicitly explains *how* they compromised (Negotiation Log) is superior to a plan that just lists a schedule without context.

**Final Verdict:**
Based on the above, which plan would a human prefer? 
(Prioritize "Satisfaction" and "Process" over "Mechanical Perfection" unless there is a fatal error.)

You must output ONLY the winner (A or B). Do NOT include any reasoning."""


USER_PROMPT_TEMPLATE = """Here are the two plans:

<plan_A>
[Schedule]: {schedule_a}
[Willingness]: {willingness_a}
[Process]: {process_a}
[FPR]: {fpr_a}
</plan_A>

<plan_B>
[Schedule]: {schedule_b}
[Willingness]: {willingness_b}
[Process]: {process_b}
[FPR]: {fpr_b}
</plan_B>"""


# ============================================================
# Judge Function
# ============================================================

def judge_travel_plans(
    plan_a: TravelPlan,
    plan_b: TravelPlan,
    model: str = "gpt-4.1-mini",
    temperature: float = 0.0,
) -> JudgeResult:
    """
    두 여행 계획을 비교하고 Winner를 반환
    
    Args:
        plan_a: 첫 번째 여행 계획
        plan_b: 두 번째 여행 계획
        model: 사용할 LLM 모델 (기본값: gpt-4.1-mini)
            - 학술 논문용 (권장): "gpt-4.1" ($2/$8 per 1M tokens)
            - 비용 절감용: "gpt-4.1-mini" (~$0.4/$1.6 per 1M tokens)  
            - 초저비용: "gpt-4.1-nano" ($0.02/$0.15 per 1M tokens)
            - 멀티모달: "gpt-4o" ($2.5/$10 per 1M tokens)
        temperature: LLM temperature (기본값: 0.0, 결정론적 출력)
    
    Returns:
        JudgeResult: winner 필드에 "A" 또는 "B" 포함
    
    Example:
        >>> result = judge_travel_plans(plan_a, plan_b, model="gpt-4.1")
        >>> print(result.winner)  # Winner.A or Winner.B
        >>> print(result.winner.value)  # "A" or "B"
    """
    # LLM with Structured Output
    llm = ChatOpenAI(
        model=model,
        temperature=temperature,
    )
    
    # Structured Output 바인딩
    structured_llm = llm.with_structured_output(JudgeResult)
    
    # Prompt Template 생성
    prompt = ChatPromptTemplate.from_messages([
        ("system", SYSTEM_PROMPT),
        ("user", USER_PROMPT_TEMPLATE)
    ])
    
    # Chain 구성
    chain = prompt | structured_llm
    
    # Chain 실행
    result = chain.invoke({
        "schedule_a": plan_a.schedule,
        "willingness_a": plan_a.willingness,
        "process_a": plan_a.process,
        "fpr_a": plan_a.fpr,
        "schedule_b": plan_b.schedule,
        "willingness_b": plan_b.willingness,
        "process_b": plan_b.process,
        "fpr_b": plan_b.fpr,
    })
    
    return result


# ============================================================
# Convenience Function
# ============================================================

def judge_travel_plans_simple(
    plan_a: TravelPlan,
    plan_b: TravelPlan,
    model: str = "gpt-4.1-mini",
) -> Literal["A", "B"]:
    """
    간단한 인터페이스 - Winner 문자열만 반환
    
    Args:
        plan_a: 첫 번째 여행 계획
        plan_b: 두 번째 여행 계획
        model: 사용할 LLM 모델
    
    Returns:
        "A" 또는 "B"
    """
    result = judge_travel_plans(plan_a, plan_b, model=model)
    return result.winner.value