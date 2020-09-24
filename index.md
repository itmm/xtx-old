# Extended Text Library

```
@Def(file: xtx.h)
	#pragma once
	@put(includes)
	namespace xtx {
		@put(globals)
	}
@End(file: xtx.h)
```

```
@Def(file: xtx.cpp)
	#define xtx_IMPL 1
	#include "xtx.h"
@End(file: xtx.cpp)
```

```
@def(globals)
	class State {
	public:
		int line { 1 };
		int column { 0 };
		int soft_break_at { 73 };
		int level { 0 };
		bool first { false };
	};
@end(globals)
```

```
@def(includes)
	#include <iostream>
	#include <memory>
	#include <vector>
@end(includes)
```

```
@add(globals)
	class Node;
	using Node_Ptr = std::unique_ptr<Node>;
	using Nodes = std::vector<Node_Ptr>;

	class Node {
	public:
		virtual ~Node() {}
		virtual void write(std::ostream &out, State &state) const = 0;
	protected:
		void add_space(std::ostream &out, State &state, int size) const {
			if (state.first) {
				state.first = false;
			} else {
				if (state.column > 0 && state.soft_break_at > 0 && state.column + 1 + size <= state.soft_break_at) {
					out << ' '; ++state.column;
				} else {
					out << '\n'; state.column = 0; ++state.line;
				}
			}
		}
	};

	std::ostream &operator<<(std::ostream &out, const Node &n) {
		State state {};
		n.write(out, state);
		return out;
	}
@end(globals)
```

```
@add(globals)
	class Plain: public Node {
		const std::string plain_;
	public:
		Plain(const std::string &plain): plain_ { plain } {};
		void write(std::ostream &out, State &state) const {
			add_space(out, state, plain_.size());
			out << plain_; state.column += plain_.size();
		}
	};
@end(globals)
```

```
@add(globals)
	class Level: public Node {
		const std::string name_;
		Nodes childs_;
	public:
		Level(const std::string &name = std::string {}): name_ { name } {}
		const std::string &name() const { return name_; }
		void write(std::ostream &out, State &state) const;
		Level &operator+=(Node_Ptr &&node) {
			childs_.push_back(std::move(node));
			return *this;
		}
	};

	#if xtx_IMPL
		void Level::write(std::ostream &out, State &state) const {
			++state.level;
			if (! name_.empty()) {
				if (state.column > 0) {
					out << '\n'; ++state.line; state.column = 0;
				}
				for (int i { state.level }; i; --i) {
					out << '#';
				}
				out << ' ' << name_ << "\n\n";
				state.column = 0; state.line += 2;
			}
			for (const auto &c: childs_) {
				c->write(out, state);
			}
			out << '\n';
			state.column = 0; ++state.line;
		}
	#endif
@end(globals)
```

```
@Add(file: xtx.h)
	#if xtx_IMPL
		int main() {
			xtx::Level root { "root" };
			xtx::Node_Ptr mid { new xtx::Level {} };
			xtx::Node_Ptr sub { new xtx::Level { "sub" } };
			((xtx::Level &) *mid) += std::move(sub);
			root += std::move(mid);
			std::cout << "// BEGIN\n";
			std::cout << root;
			std::cout << "// END\n";
		}
	#endif
@End(file: xtx.h)
```
