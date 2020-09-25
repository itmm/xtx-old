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
		void assure_newline(std::ostream &out, State &state) const {
			if (state.column > 0) {
				out << '\n'; state.column = 0; ++state.line;
			}
		}
		void add_space(std::ostream &out, State &state, int size) const {
			if (state.first) {
				state.first = false;
			} else {
				if (state.column > 0 && (state.soft_break_at < 0 || state.column + 1 + size <= state.soft_break_at)) {
					out << ' '; ++state.column;
				} else {
					assure_newline(out, state);
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
	class Group: public Node {
		bool one_line_;
		Nodes childs_;
	public:
		Group(bool one_line = false): one_line_ { one_line } {}
		bool one_line() const { return one_line_; }
		void one_line(bool ol) { one_line_ = ol; }
		void write(std::ostream &out, State &state) const;
		Group &operator+=(Node_Ptr &&node) {
			childs_.push_back(std::move(node));
			return *this;
		}
	};

	using Group_Ptr = std::unique_ptr<Group>;

	#if xtx_IMPL
		void Group::write(std::ostream &out, State &state) const {
			int old_soft_break_at { state.soft_break_at };
			if (one_line_) { state.soft_break_at = -1; };
			state.first = true;
			for (const auto &c: childs_) {
				c->write(out, state);
			}
			state.soft_break_at = old_soft_break_at;
		}
	#endif
@end(globals)
```

```
@add(globals)
	class Level: public Group {
		Group_Ptr name_;
		Nodes childs_;
	public:
		Level() {}
		Level(Group_Ptr &&name): name_ { std::move(name) } {
			name_->one_line(true);
		}
		Group_Ptr &name() { return name_; }
		void write(std::ostream &out, State &state) const;
	};

	#if xtx_IMPL
		class State_Inc {
			State &state_;
		public:
			State_Inc(State &state): state_ { state } {
				++state_.level;
			}
			~State_Inc() { --state_.level; }
		};

		void Level::write(std::ostream &out, State &state) const {
			State_Inc si { state };
			if (name_) {
				assure_newline(out, state);
				for (int i { state.level }; i; --i) {
					out << '#'; ++state.column;
				}
				out << ' '; ++state.column;
				out << *name_;
				assure_newline(out, state);
				out << '\n'; ++state.line;
			}
			Group::write(out, state);
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
			auto root_name = std::make_unique<xtx::Group>();
			*root_name += std::move(std::make_unique<xtx::Plain>("root"));
			xtx::Level root { std::move(root_name) };
			auto mid  = std::make_unique<xtx::Level>();
			auto sub_name  = std::make_unique<xtx::Group>();
			*sub_name += std::move(std::make_unique<xtx::Plain>("sub"));
			*sub_name += std::move(std::make_unique<xtx::Plain>("test"));
			auto sub  = std::make_unique<xtx::Level>(std::move(sub_name));
			*mid += std::move(sub);
			root += std::move(mid);
			std::cout << "// BEGIN\n";
			std::cout << root;
			std::cout << "// END\n";
		}
	#endif
@End(file: xtx.h)
```
