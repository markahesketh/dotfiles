import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pr_common import PR_URL_RE, commentable_lines, validate_comments

DIFF = """\
diff --git a/src/foo.ts b/src/foo.ts
index 1111111..2222222 100644
--- a/src/foo.ts
+++ b/src/foo.ts
@@ -10,4 +10,5 @@ function foo() {
 const a = 1;
-const b = 2;
+const b = 3;
+const c = 4;
 return a + b;
 }
diff --git a/src/new.ts b/src/new.ts
new file mode 100644
--- /dev/null
+++ b/src/new.ts
@@ -0,0 +1,2 @@
+export const x = 1;
+export const y = 2;
"""


class UrlParsing(unittest.TestCase):
    def test_extracts_owner_repo_number(self):
        m = PR_URL_RE.search("https://github.com/cli/cli/pull/9000")
        self.assertEqual((m.group(1), m.group(2), m.group(3)), ("cli", "cli", "9000"))


class CommentableLines(unittest.TestCase):
    def test_right_side_has_added_and_context_lines(self):
        lines = commentable_lines(DIFF)
        self.assertEqual(lines["src/foo.ts"]["RIGHT"], {10, 11, 12, 13, 14})
        self.assertEqual(lines["src/new.ts"]["RIGHT"], {1, 2})

    def test_left_side_has_deleted_and_context_lines(self):
        lines = commentable_lines(DIFF)
        self.assertEqual(lines["src/foo.ts"]["LEFT"], {10, 11, 12, 13})
        self.assertEqual(lines["src/new.ts"]["LEFT"], set())


class ValidateComments(unittest.TestCase):
    def test_accepts_lines_in_diff(self):
        comments = [
            {"path": "src/foo.ts", "line": 11, "body": "x"},
            {"path": "src/foo.ts", "line": 11, "side": "LEFT", "body": "x"},
        ]
        self.assertEqual(validate_comments(comments, DIFF), [])

    def test_rejects_line_outside_hunk(self):
        problems = validate_comments([{"path": "src/foo.ts", "line": 99, "body": "x"}], DIFF)
        self.assertEqual(len(problems), 1)
        self.assertIn("src/foo.ts:99", problems[0])

    def test_rejects_unknown_path(self):
        problems = validate_comments([{"path": "src/nope.ts", "line": 1, "body": "x"}], DIFF)
        self.assertIn("not in the diff", problems[0])

    def test_rejects_missing_keys(self):
        problems = validate_comments([{"path": "src/foo.ts", "line": 11}], DIFF)
        self.assertIn("missing 'body'", problems[0])


if __name__ == "__main__":
    unittest.main()
