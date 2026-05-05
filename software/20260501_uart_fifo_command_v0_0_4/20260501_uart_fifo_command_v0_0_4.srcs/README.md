# UART + FIFO 기반 다중 센서 데이터 처리 및 명령 제어 시스템 설계

## 📌 프로젝트 개요

Verilog HDL 기반으로 UART 통신을 이용하여 다중 센서와 타이머 기능을 제어하는 Command-Driven System을 설계하고 구현하였습니다.

사용자가 UART를 통해 ASCII 명령어를 입력하면 이를 파싱하여 센서 동작 또는 시간 기능을 수행하고, 결과를 UART로 출력하는 구조입니다.

또한 FIFO 기반 버퍼링과 타이밍 제어를 적용하여 데이터 유실 및 동기화 문제를 해결하고 시스템 안정성을 향상시켰습니다.

---

## 🎯 개발 목표

- UART 기반 명령어 처리 시스템 구현
- Command Parser / Executor 구조 설계
- FIFO 기반 데이터 버퍼링 및 안정성 확보
- 초음파 센서 및 DHT11 센서 인터페이스 구현
- Stopwatch / Watch 기능 통합
- 비동기 입력 처리 및 타이밍 문제 해결

---

## 🏗 시스템 구조

UART RX → FIFO RX → Line Collector → Command Parser → Command Executor  
→ Sensor / Timer Module → UART TX Controller → FIFO TX → UART TX

---

## 🧾 명령어 구성

| 명령어 | 기능 |
|--------|------|
| STOPWATCH RUN/STOP | 스톱워치 시작/정지 |
| STOPWATCH CLEAR | 스톱워치 초기화 |
| STOPWATCH MODE | 업/다운 카운트 전환 |
| WATCH HH:MM:SS:MS | 시간 설정 |
| WATCH TIME | 현재 시간 출력 |
| ULTRASONIC | 거리 측정 |
| DHT11 | 온습도 측정 |
| 기타 입력 | ERROR 출력 |

---

## 🛠 주요 설계 특징

### 1. FIFO 기반 데이터 처리

UART 입력 데이터를 FIFO로 버퍼링하여 데이터 손실 없이 안정적으로 처리하도록 설계하였습니다.

또한 FIFO 상태(full/empty)를 기반으로 read/write를 제어하여 데이터 무결성을 확보하였습니다.

---

### 2. Command Parser / Executor 구조

입력된 ASCII 명령어를 Parser에서 해석하고, Executor에서 해당 기능을 수행하도록 모듈을 분리하여 설계하였습니다.

이를 통해 기능 확장성과 구조적 가독성을 확보하였습니다.

---

### 3. 비동기 입력 안정화

센서 입력 신호는 FPGA 클럭과 비동기이므로 메타스테빌리티 문제가 발생할 수 있습니다.

이를 해결하기 위해 2-stage Synchronizer를 적용하여 안정적인 신호 처리를 구현하였습니다.

---

## 🛠 트러블 슈팅

### 1. FIFO Overflow 문제

- 문제: FIFO 크기(16byte)를 초과하는 데이터 입력 시 데이터 유실 발생  
- 원인: FIFO full 상태에서도 write 발생  
- 해결: FIFO full 상태에서는 write를 제한하도록 제어 로직 수정  

---

### 2. FIFO Read 타이밍 문제

- 문제: Enter 입력 후 명령이 즉시 실행되지 않음  
- 원인: FIFO r_en과 dout valid 타이밍 불일치 (1-cycle latency)  
- 해결: line_collector FSM에 S_WAIT 상태 추가  

---

### 3. 초음파 센서 전송 누락 문제

- 문제: 거리 측정 후 UART TX Controller로 데이터가 전송되지 않음  
- 원인: done 신호가 1클럭만 유지되어 Controller가 인식하지 못함  
- 해결: FSM에 STOP 상태 추가하여 데이터 유지 후 전송  

---

### 4. 비동기 센서 입력 문제

- 문제: 센서 데이터가 불안정하거나 오동작 발생  
- 원인: 비동기 입력을 직접 FSM에 사용  
- 해결: 2-stage Synchronizer 적용  

---

### 5. DHT11 Inout 충돌 문제

- 문제: 신호 충돌 및 데이터 이상 발생  
- 원인: 입력과 출력이 동일 라인 공유  
- 해결: 내부 레지스터(dht11_reg)로 분리하여 제어  

---

## 🚀 결과

- UART 기반 명령어 처리 시스템 구현 완료
- 센서 및 타이머 기능 통합
- FIFO 및 타이밍 문제 해결을 통한 안정성 확보
- 실제 시스템 수준의 디버깅 경험 확보

---