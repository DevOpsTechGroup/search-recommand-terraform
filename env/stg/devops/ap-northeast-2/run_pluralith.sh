#!/bin/bash
echo -e "----------------------------"
echo -e "Pluralith 시각화 시작..."
echo -e "----------------------------"
echo

# Pluralith API KEY 입력을 사용자로부터 입력 받는다
# Pluralith API KEY의 경우 https://app.pluralith.com 로그인 후 확인 가능
PLURALITH_API_KEY=$1
if [[ -z "$PLURALITH_API_KEY" ]]; then
  echo "Pluralith API KEY는 최초로 한번 설정이 되어야 합니다."
  exit 1;
fi

echo -e "----------------------------"
echo -e "Pluralith 로그인 수행"
echo -e "----------------------------"
pluralith login --api-key $PLURALITH_API_KEY
echo

echo -e "----------------------------"
echo -e "Pluralith Graph 시각화 수행"
echo -e "----------------------------"
pluralith graph