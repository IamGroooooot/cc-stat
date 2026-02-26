# cc-stat

Claude Code statusline을 한 줄로 보기 좋게 보여주는 스크립트입니다.

```text
Model Claude 4 Opus ▰▰▱▱▱ 42%/200K 85.3K $0.47 dur 3m12s(api 1m45s) +120/-34
```

아이콘 버전은 Nerd Font가 있는 터미널에서만 정상 표시됩니다.

## 30초 설치

### 1) 이미 레포를 클론한 경우

```sh
cd cc-stat
./cc-stat install
./cc-stat doctor
```

### 2) 클론 없이 GitHub에서 바로 설치

```sh
curl -fsSL -o /tmp/cc-stat-install.sh \
  https://raw.githubusercontent.com/IamGroooooot/cc-stat/main/install-from-github.sh
sh /tmp/cc-stat-install.sh --repo IamGroooooot/cc-stat
```

버전 고정(권장):

```sh
sh /tmp/cc-stat-install.sh --repo IamGroooooot/cc-stat --ref v1.2.3
```

## 기본 사용

설치:

```sh
./cc-stat install
```

상태 점검:

```sh
./cc-stat doctor
```

삭제:

```sh
./cc-stat uninstall
```

## 명령어 요약

```sh
./cc-stat install
./cc-stat uninstall
./cc-stat doctor
./cc-stat install-github --repo IamGroooooot/cc-stat
```

직접 스크립트를 실행해도 됩니다:
- `./install.sh`
- `./uninstall.sh`
- `./doctor.sh`
- `./install-from-github.sh`

## 요구사항

- `jq` (필수)
- Claude Code
- Nerd Font 터미널 (선택, 아이콘 표시용)

`jq`가 없으면:

```sh
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

## 표시 정보

| 항목 | 의미 |
|---|---|
| Model label | 현재 모델 |
| Agent label | 에이전트 이름(팀 사용 시) |
| ▰▰▱▱▱ | 컨텍스트 사용량 게이지 |
| `42%/200K` | 사용률 / 컨텍스트 크기 |
| `85.3K` | 총 토큰(input + output) |
| `$0.47` | 누적 비용 |
| `dur 3m12s(api 1m45s)` | 전체/API 소요 시간 |
| `+120/-34` | 추가/삭제 라인 수 |

색상 임계값:
- 경고: `60%+`
- 높음: `80%+`
- 치명: `exceeds_200k_tokens=true`

환경변수로 조정 가능:
- `CC_STAT_WARN_PCT` (기본 `60`)
- `CC_STAT_HIGH_PCT` (기본 `80`)

## 자주 쓰는 옵션

```sh
./cc-stat install --help
```

주요 옵션:
- `--config-dir DIR`: Claude 설정 디렉터리 (기본: `$CLAUDE_CONFIG_DIR` 또는 `~/.claude`)
- `--script-name NAME`: 설치될 파일명 (기본: `statusline.sh`)
- `--source-script FILE`: 커스텀 statusline 소스 경로
- `--force`: 기존 스크립트 덮어쓰기
- `--dry-run`: 실제 변경 없이 미리보기

`statusLine.command`가 다른 파일을 가리켜도 강제로 제거하려면:

```sh
./cc-stat uninstall --all-statusline
```

## 커스터마이징

설치된 스크립트(기본: `~/.claude/statusline.sh`)를 수정하면 아이콘/색상/필드 순서를 바꿀 수 있습니다.

## License

MIT
