#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: install-agents.sh --project-dir ABSOLUTE_PATH --confirm-vibe-coding --coding-agent codex|claude-code|both [--replace-existing] [--add-claude-import]'
}

project_dir=''
confirmed='false'
replace_existing='false'
add_claude_import='false'
coding_agent=''

while (($# > 0)); do
  case "$1" in
    --project-dir)
      if (($# < 2)); then
        usage >&2
        exit 2
      fi
      project_dir="$2"
      shift 2
      ;;
    --confirm-vibe-coding)
      confirmed='true'
      shift
      ;;
    --coding-agent)
      if (($# < 2)); then
        usage >&2
        exit 2
      fi
      coding_agent="$2"
      shift 2
      ;;
    --replace-existing)
      replace_existing='true'
      shift
      ;;
    --add-claude-import)
      add_claude_import='true'
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'error=unknown_argument argument=%s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$confirmed" != 'true' ]]; then
  printf '%s\n' 'error=vibe_coding_not_confirmed' >&2
  exit 2
fi

if [[ -z "$project_dir" || "$project_dir" != /* ]]; then
  printf '%s\n' 'error=project_dir_must_be_absolute' >&2
  exit 2
fi

case "$coding_agent" in
  codex)
    needs_claude_bridge='false'
    ;;
  claude-code|both)
    needs_claude_bridge='true'
    ;;
  *)
    printf 'error=invalid_coding_agent value=%s\n' "$coding_agent" >&2
    exit 2
    ;;
esac

if [[ "$needs_claude_bridge" == 'false' && "$add_claude_import" == 'true' ]]; then
  printf '%s\n' 'error=claude_import_not_applicable' >&2
  exit 2
fi

if [[ ! -d "$project_dir" ]]; then
  printf 'error=project_dir_not_found path=%s\n' "$project_dir" >&2
  exit 2
fi

project_dir="$(cd "$project_dir" && pwd -P)"
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_file="$skill_dir/assets/AGENTS.md"
target_file="$project_dir/AGENTS.md"
claude_file="$project_dir/CLAUDE.md"

if [[ ! -f "$source_file" ]]; then
  printf 'error=missing_skill_asset path=%s\n' "$source_file" >&2
  exit 2
fi

if [[ -e "$target_file" && ! -f "$target_file" ]]; then
  printf 'error=target_is_not_regular_file path=%s\n' "$target_file" >&2
  exit 3
fi

target_existed='false'
if [[ -f "$target_file" ]]; then
  target_existed='true'
fi

if [[ "$target_existed" == 'true' ]] && cmp -s "$source_file" "$target_file"; then
  agents_action='unchanged'
elif [[ "$target_existed" == 'true' && "$replace_existing" != 'true' ]]; then
  printf 'status=conflict target=%s action=explicit_replace_required\n' "$target_file" >&2
  exit 3
elif [[ "$target_existed" == 'true' ]]; then
  agents_action='replaced'
else
  agents_action='created'
fi

claude_action='not_requested'
if [[ "$needs_claude_bridge" == 'true' ]]; then
  if [[ -L "$claude_file" ]]; then
    claude_link="$(readlink "$claude_file")"
    if [[ "$claude_link" == 'AGENTS.md' || "$claude_link" == './AGENTS.md' || "$claude_link" == "$target_file" ]]; then
      claude_action='unchanged_symlink'
    else
      printf 'status=conflict target=%s action=unsupported_symlink\n' "$claude_file" >&2
      exit 3
    fi
  elif [[ -e "$claude_file" && ! -f "$claude_file" ]]; then
    printf 'error=claude_target_is_not_regular_file path=%s\n' "$claude_file" >&2
    exit 3
  elif [[ -f "$claude_file" ]] && grep -Eq '^[[:space:]]*@AGENTS\.md[[:space:]]*$' "$claude_file"; then
    claude_action='unchanged'
  elif [[ -f "$claude_file" && "$add_claude_import" != 'true' ]]; then
    printf 'status=conflict target=%s action=explicit_import_authorization_required\n' "$claude_file" >&2
    exit 3
  elif [[ -f "$claude_file" ]]; then
    claude_action='import_added'
  else
    claude_action='created'
  fi
fi

temporary_agents=''
temporary_claude=''
cleanup() {
  if [[ -n "${temporary_agents:-}" && -e "$temporary_agents" ]]; then
    rm -f -- "$temporary_agents"
  fi
  if [[ -n "${temporary_claude:-}" && -e "$temporary_claude" ]]; then
    rm -f -- "$temporary_claude"
  fi
}
trap cleanup EXIT

if [[ "$agents_action" != 'unchanged' ]]; then
  temporary_agents="$(mktemp "$project_dir/.AGENTS.md.install.XXXXXX")"
  cp -- "$source_file" "$temporary_agents"
  chmod 0644 "$temporary_agents"
  mv -f -- "$temporary_agents" "$target_file"
  temporary_agents=''
fi

if ! cmp -s "$source_file" "$target_file"; then
  printf 'error=verification_failed target=%s\n' "$target_file" >&2
  exit 4
fi

if [[ "$claude_action" == 'created' ]]; then
  temporary_claude="$(mktemp "$project_dir/.CLAUDE.md.install.XXXXXX")"
  printf '%s\n' '@AGENTS.md' > "$temporary_claude"
  chmod 0644 "$temporary_claude"
  mv -f -- "$temporary_claude" "$claude_file"
  temporary_claude=''
elif [[ "$claude_action" == 'import_added' ]]; then
  temporary_claude="$(mktemp "$project_dir/.CLAUDE.md.install.XXXXXX")"
  cp -- "$claude_file" "$temporary_claude"
  if [[ -s "$temporary_claude" ]]; then
    last_byte="$(tail -c 1 "$temporary_claude" | od -An -t u1 | tr -d '[:space:]')"
    if [[ "$last_byte" != '10' ]]; then
      printf '\n' >> "$temporary_claude"
    fi
  fi
  printf '%s\n' '@AGENTS.md' >> "$temporary_claude"
  chmod 0644 "$temporary_claude"
  mv -f -- "$temporary_claude" "$claude_file"
  temporary_claude=''
fi

if [[ "$needs_claude_bridge" == 'true' ]]; then
  if [[ "$claude_action" == 'unchanged_symlink' ]]; then
    claude_verified='symlink_to_agents'
  elif grep -Eq '^[[:space:]]*@AGENTS\.md[[:space:]]*$' "$claude_file"; then
    claude_verified='import_present'
  else
    printf 'error=claude_bridge_verification_failed target=%s\n' "$claude_file" >&2
    exit 4
  fi
else
  claude_verified='not_requested'
fi

printf 'agents_status=%s agents_target=%s agents_verified=identical coding_agent=%s claude_status=%s claude_target=%s claude_verified=%s\n' \
  "$agents_action" "$target_file" "$coding_agent" "$claude_action" "$claude_file" "$claude_verified"
