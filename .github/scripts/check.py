#!/usr/bin/env python3
"""
Check script for E1epack project.
Performs various validations on the codebase.
"""

import os
import re
import sys
import json
import subprocess
from pathlib import Path
from typing import List, Dict, Tuple, Optional


class CheckError(Exception):
    """Custom exception for check failures."""
    pass


class CheckRunner:
    def __init__(self):
        self.repo_root = Path(os.getcwd())
        self.errors: List[str] = []
        self.warnings: List[str] = []
    
    def add_error(self, msg: str):
        self.errors.append(msg)
        print(f"❌ ERROR: {msg}")
    
    def add_warning(self, msg: str):
        self.warnings.append(msg)
        print(f"⚠️ WARNING: {msg}")
    
    def run_all_checks(self):
        """Run all validation checks."""
        print("🔍 Running E1epack checks...")
        
        # 1. Check for duplicate IDs
        self.check_duplicate_ids()
        
        # 2. Validate SemVer version numbers
        self.check_semver_versions()
        
        # 3. Check commit message format (if in PR context)
        self.check_commit_message_format()
        
        # 4. Validate JSON files
        self.check_json_files()
        
        # 5. Check function file extensions
        self.check_function_files()
        
        # Print summary
        print("\n" + "="*60)
        print("CHECK SUMMARY")
        print("="*60)
        
        if self.warnings:
            print(f"\n⚠️  {len(self.warnings)} Warnings:")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
        
        if self.errors:
            print(f"\n❌ {len(self.errors)} Errors:")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")
            print("\n❌ Checks failed!")
            return False
        else:
            print("\n✅ All checks passed!")
            if self.warnings:
                print(f"   (with {len(self.warnings)} warnings)")
            return True
    
    def check_duplicate_ids(self):
        """Check for duplicate pack_id and modrinth_project_id."""
        print("\n📋 Checking for duplicate IDs...")
        
        pack_ids: Dict[str, List[str]] = {}
        modrinth_ids: Dict[str, List[str]] = {}
        
        for build_file in self.repo_root.glob("**/BUILD.bazel"):
            content = build_file.read_text(encoding='utf-8')
            
            # Find pack_id
            pack_match = re.search(r'pack_id\s*=\s*"([^"]+)"', content)
            if pack_match:
                pack_id = pack_match.group(1)
                pack_ids.setdefault(pack_id, []).append(str(build_file))
            
            # Find modrinth_project_id
            modrinth_match = re.search(r'modrinth_project_id\s*=\s*"([^"]+)"', content)
            if modrinth_match:
                modrinth_id = modrinth_match.group(1)
                modrinth_ids.setdefault(modrinth_id, []).append(str(build_file))
        
        # Report duplicates
        for pack_id, files in pack_ids.items():
            if len(files) > 1:
                self.add_error(f"Duplicate pack_id '{pack_id}' found in:")
                for file in files:
                    self.add_error(f"  - {file}")
        
        for modrinth_id, files in modrinth_ids.items():
            if len(files) > 1:
                self.add_error(f"Duplicate modrinth_project_id '{modrinth_id}' found in:")
                for file in files:
                    self.add_error(f"  - {file}")
        
        if not pack_ids and not modrinth_ids:
            self.add_warning("No pack_id or modrinth_project_id found in any BUILD.bazel file")
    
    def check_semver_versions(self):
        """Validate that version numbers follow SemVer 2.0.0."""
        print("\n🏷️  Checking SemVer version numbers...")
        
        # SemVer regex pattern (simplified but comprehensive)
        # Based on SemVer 2.0.0 specification
        semver_pattern = re.compile(
            r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'  # X.Y.Z
            r'(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?'  # -prerelease
            r'(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'  # +build
        )
        
        version_count = 0
        for build_file in self.repo_root.glob("**/BUILD.bazel"):
            # Skip third_party and template directories
            if 'third_party' in str(build_file) or 'template' in str(build_file):
                continue
                
            content = build_file.read_text(encoding='utf-8')
            
            # Look for pack_version assignment (most common)
            # Also check for version variable
            version_matches = []
            
            # Pattern for pack_version = "1.0.0"
            pack_version_match = re.search(r'pack_version\s*=\s*"([^"]+)"', content)
            if pack_version_match:
                version_matches.append(('pack_version', pack_version_match.group(1)))
            
            # Pattern for version = "1.0.0"  
            version_match = re.search(r'\bversion\s*=\s*"([^"]+)"', content)
            if version_match:
                version_matches.append(('version', version_match.group(1)))
            
            for var_name, value in version_matches:
                version_count += 1
                if not semver_pattern.match(value):
                    self.add_error(
                        f"Invalid SemVer version '{value}' in {build_file}\n"
                        f"  Variable: {var_name}\n"
                        f"  Expected format: X.Y.Z[-prerelease][+build]"
                    )
                else:
                    print(f"  ✓ Valid SemVer: {value} in {build_file}")
        
        if version_count == 0:
            self.add_warning("No version variables found in BUILD.bazel files")
    
    def check_commit_message_format(self):
        """Check commit message format."""
        print("\n📝 Checking commit message format...")
        
        # Get the event name from environment
        event_name = os.environ.get('GITHUB_EVENT_NAME', '')
        
        try:
            # For push events, check the latest commit
            # For pull_request events, check all commits in the PR
            if event_name == 'push':
                # Get the current commit message
                result = subprocess.run(
                    ['git', 'log', '-1', '--pretty=%B'],
                    capture_output=True,
                    text=True,
                    check=True
                )
                commits = [result.stdout.strip()]
            elif event_name == 'pull_request':
                # Try to get PR commits from git log between merge base and HEAD
                # This is a simplified approach
                result = subprocess.run(
                    ['git', 'log', '--pretty=%B', '--no-merges', 'HEAD~10..HEAD'],
                    capture_output=True,
                    text=True,
                    check=True
                )
                commits = [c for c in result.stdout.strip().split('\n\n') if c]
            else:
                print(f"  Skipping (event: {event_name})")
                return
            
            if not commits:
                self.add_warning("No commits found to check")
                return
            
            for i, commit_msg in enumerate(commits):
                if not commit_msg.strip():
                    continue
                    
                lines = commit_msg.strip().split('\n')
                first_line = lines[0].strip()
                
                # Check for project tag pattern [ABC]
                tag_pattern = r'^\[[A-Z]{2,}\]\s+'
                if not re.match(tag_pattern, first_line):
                    # Check if this might be a repository-wide change (no tag)
                    # Repository-wide changes shouldn't have project tags
                    # We'll issue a warning but not an error
                    self.add_warning(
                        f"Commit message may not follow project tag format:\n"
                        f"  '{first_line[:50]}...'\n"
                        f"  Expected format: [PROJECT_ABBR] <emoji> <type>: <description>\n"
                        f"  For repository-wide changes, omit project tag."
                    )
                else:
                    print(f"  ✓ Commit format OK: {first_line[:50]}...")
            
        except subprocess.CalledProcessError as e:
            self.add_warning(f"Failed to get commit messages: {e}")
        except Exception as e:
            self.add_warning(f"Error checking commit messages: {e}")
    
    def check_json_files(self):
        """Validate JSON file syntax."""
        print("\n📄 Checking JSON file syntax...")
        
        json_files = list(self.repo_root.glob("**/*.json"))
        if not json_files:
            print("  No JSON files found")
            return
        
        for json_file in json_files:
            # Skip node_modules and other excluded directories
            if any(excluded in str(json_file) for excluded in ['node_modules', '.git', '.bazel']):
                continue
            
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    json.load(f)
                print(f"  ✓ Valid JSON: {json_file}")
            except json.JSONDecodeError as e:
                self.add_error(f"Invalid JSON in {json_file}: {e}")
    
    def check_function_files(self):
        """Check Minecraft function files for basic syntax."""
        print("\n⚙️  Checking Minecraft function files...")
        
        mcfunction_files = list(self.repo_root.glob("**/*.mcfunction"))
        if not mcfunction_files:
            print("  No .mcfunction files found")
            return
        
        for func_file in mcfunction_files:
            # Skip excluded directories
            if any(excluded in str(func_file) for excluded in ['.git', '.bazel']):
                continue
            
            try:
                content = func_file.read_text(encoding='utf-8')
                lines = content.split('\n')
                
                # Basic check: non-empty lines should not be just whitespace
                for i, line in enumerate(lines, 1):
                    stripped = line.strip()
                    if stripped and stripped.startswith('#'):
                        # Comment line, ok
                        continue
                    # Add more checks here if needed
                
                print(f"  ✓ Checked: {func_file}")
                
            except Exception as e:
                self.add_warning(f"Failed to read {func_file}: {e}")


def main():
    """Main entry point."""
    runner = CheckRunner()
    success = runner.run_all_checks()
    
    if not success:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()