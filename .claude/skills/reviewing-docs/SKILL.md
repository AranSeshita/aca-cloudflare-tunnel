---
name: reviewing-docs
description: このリポジトリの README（ルート / 各モジュール）と .tf コメントを、正確さ・一貫性・簡潔さの観点でレビューする。README を書いた/更新した、.tf コメントを整えた、公開前に最終確認したいときに使う。README の Inputs/Outputs 表と variables.tf/outputs.tf の突き合わせ、他プロジェクト由来の記述（service_bus / openai / key_vault / renderer 等）や旧参照の検出を含む。
---

# ドキュメントレビュー

対象: ルート `README.md`、各 `modules/*/README.md`、`.tf` 内コメント。
指摘は「ファイル・行・問題・修正案」を具体的に出す。修正を頼まれたら適用する。

## 進め方

このチェックリストを回答にコピーして進捗を管理する:

```
- [ ] 1. 対象ファイルを読む（README と対応する .tf）
- [ ] 2. Inputs/Outputs 表を variables.tf / outputs.tf と突き合わせる
- [ ] 3. 観点ごとに指摘を洗い出す
- [ ] 4. 重要度順に提示（依頼があれば修正を適用）
- [ ] 5. コメントのみの変更なら fmt / validate に影響しないことを確認
```

突き合わせに使うコマンド:

```bash
grep -nE "variable|output" modules/<m>/*.tf                 # 実在する変数 / 出力名
grep -rniE "service_bus|openai|key_vault|renderer|civil\.example|container_registroy" --include="*.md" .  # 他PJ由来 / 旧参照
```

## 観点

### 正確さ（最優先）

- README の Inputs / Outputs 表が `variables.tf` / `outputs.tf` と一致（名前・型・デフォルト・過不足）。
- コード例（HCL）が実在の変数名・モジュール出力・source パスを指す（廃止した変数や旧ディレクトリ名を参照しない）。
- 手順（`init` / `plan` / `apply`、tfvars に埋める値）が実態と一致。

### 一貫性

- 言語: コメント・本文は日本語で統一（製品名 / 技術用語の英語は可）。
- 構成: 各モジュール README が `Usage` / `Inputs` / `Outputs` / `Notes` で統一。
- 用語: 同一概念に別表記が混ざらない。
- 他プロジェクト由来の記述が残っていない。

### 簡潔さ

- 冗長・重複を削る（1 項目 1 メッセージ）。
- 箇条書きの文体を揃える（名詞句 or 文で統一）。
- 見出し階層・表・コードブロックが崩れていない。

## 出力フォーマット

```
## <ファイル>
- [正確さ] L<行>: <問題> → <修正案>
- [一貫性] L<行>: ...
```

指摘ゼロなら「問題なし」と明記する。
