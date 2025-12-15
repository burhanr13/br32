use std::io::Read;

use crate::assembler::State;

#[derive(Clone, Debug, PartialEq)]
pub enum Token {
    Ident(String),

    IntLit(u32),
    StringLit(Vec<u8>),

    NewLine,
    Colon,
    Comma,
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    And,
    Or,
    Xor,
    Not,
    Shl,
    Shr,
    LParen,
    RParen,
}

fn advance(s: &mut State) -> Option<u8> {
    let n = s.nextchar;
    let mut c = [0];
    s.nextchar =
        s.fp.as_mut()
            .unwrap()
            .read_exact(&mut c)
            .ok()
            .map(|()| c[0]);
    n
}

fn skip_space(s: &mut State) {
    while let Some(c) = s.nextchar {
        match c {
            b' ' | b'\t' | b'\r' => advance(s),
            _ => break,
        };
    }
}

fn escape_char(s: &mut State) -> Option<u8> {
    Some(match advance(s)? {
        b'0' => b'\0',
        b'n' => b'\n',
        b'r' => b'\r',
        b't' => b'\t',
        b'e' => b'\x1b',
        b'x' => {
            let mut n = [0; 2];
            n[0] = advance(s)?;
            n[1] = advance(s)?;
            return u8::from_str_radix(str::from_utf8(&n).unwrap(), 16).ok();
        }
        _ => return None,
    })
}

pub fn next_token(s: &mut State) -> Option<Token> {
    if s.line == 0 {
        advance(s);
        s.line += 1;
    }
    skip_space(s);
    Some(match advance(s)? {
        b'\n' => Token::NewLine,
        b':' => Token::Colon,
        b';' => {
            while s.nextchar? != b'\n' {
                advance(s);
            }
            return next_token(s);
        }
        c @ (b'.' | b'a'..=b'z' | b'A'..=b'Z' | b'_') => {
            let mut id = String::new();
            id.push(c as char);
            while let Some(c) = s.nextchar {
                match c {
                    b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'_' => {
                        id.push(c as char);
                        advance(s);
                    }
                    _ => break,
                }
            }
            Token::Ident(id)
        }
        c @ b'0'..=b'9' => {
            let mut v = (c - b'0') as u32;
            if c == b'0' && s.nextchar == Some(b'b') {
                advance(s);
                while let Some(c) = s.nextchar {
                    match c {
                        b'0'..=b'1' => {
                            v = 2 * v + (c - b'0') as u32;
                            advance(s);
                        }
                        b'_' => {
                            advance(s);
                        }
                        _ => break,
                    }
                }
                Token::IntLit(v)
            } else if c == b'0' && s.nextchar == Some(b'x') {
                advance(s);
                while let Some(c) = s.nextchar {
                    match c {
                        b'0'..=b'9' => {
                            v = 16 * v + (c - b'0') as u32;
                            advance(s);
                        }
                        b'a'..=b'f' => {
                            v = 16 * v + (10 + c - b'a') as u32;
                            advance(s);
                        }
                        b'A'..=b'F' => {
                            v = 16 * v + (10 + c - b'A') as u32;
                            advance(s);
                        }
                        b'_' => {
                            advance(s);
                        }
                        _ => break,
                    }
                }
                Token::IntLit(v)
            } else {
                while let Some(c) = s.nextchar {
                    match c {
                        b'0'..=b'9' => {
                            v = 10 * v + (c - b'0') as u32;
                            advance(s);
                        }
                        b'_' => {
                            advance(s);
                        }
                        _ => break,
                    }
                }
                Token::IntLit(v)
            }
        }
        b'\'' => {
            let v;
            if let Some(c) = advance(s) {
                if c == b'\'' {
                    error!(s, "bad char literal")
                } else if c == b'\\' {
                    if s.nextchar == Some(b'\'') {
                        v = b'\'';
                        advance(s);
                    } else {
                        let Some(v1) = escape_char(s) else {
                            error!(s, "bad escape char");
                        };
                        v = v1;
                    }
                } else {
                    v = c;
                }
            } else {
                error!(s, "bad char literal");
            }
            if advance(s) != Some(b'\'') {
                error!(s, "bad char literal");
            }
            Token::IntLit(v as u32)
        }
        b'"' => {
            let mut v = Vec::new();
            while let Some(c) = s.nextchar {
                if c == b'"' {
                    break;
                }
                advance(s);
                if c == b'\\' {
                    if s.nextchar == Some(b'"') {
                        v.push(b'"');
                        advance(s);
                    } else {
                        let Some(v1) = escape_char(s) else {
                            error!(s, "bad escape char");
                        };
                        v.push(v1);
                    }
                } else {
                    v.push(c);
                }
            }
            if advance(s) != Some(b'"') {
                error!(s, "bad string literal");
            }
            Token::StringLit(v)
        }
        b',' => Token::Comma,
        b'+' => Token::Add,
        b'-' => Token::Sub,
        b'*' => Token::Mul,
        b'/' => Token::Div,
        b'%' => Token::Mod,
        b'&' => Token::And,
        b'|' => Token::Or,
        b'^' => Token::Xor,
        b'~' => Token::Not,
        b'<' => {
            if s.nextchar == Some(b'<') {
                advance(s);
                Token::Shl
            } else {
                error!(s, "bad token '<'")
            }
        }
        b'>' => {
            if s.nextchar == Some(b'>') {
                advance(s);
                Token::Shr
            } else {
                error!(s, "bad token '>'")
            }
        }
        b'(' => Token::LParen,
        b')' => Token::RParen,
        c => error!(s, "bad token '{}'", c as char),
    })
}
