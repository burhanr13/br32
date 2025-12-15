use std::io::Read;

use crate::{State, error};

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

impl State {
    fn advance_char(&mut self) -> Option<u8> {
        let n = self.nextchar;
        let mut c = [0];
        self.nextchar = self
            .fp
            .as_mut()
            .unwrap()
            .read_exact(&mut c)
            .ok()
            .map(|()| c[0]);
        n
    }

    fn skip_space(&mut self) {
        while let Some(c) = self.nextchar {
            match c {
                b' ' | b'\t' | b'\r' => self.advance_char(),
                _ => break,
            };
        }
    }

    fn escape_char(&mut self) -> Option<u8> {
        Some(match self.advance_char()? {
            b'0' => b'\0',
            b'n' => b'\n',
            b'r' => b'\r',
            b't' => b'\t',
            b'e' => b'\x1b',
            b'x' => {
                let mut n = [0; 2];
                n[0] = self.advance_char()?;
                n[1] = self.advance_char()?;
                return u8::from_str_radix(str::from_utf8(&n).unwrap(), 16).ok();
            }
            _ => return None,
        })
    }

    pub fn next_token(&mut self) -> Option<Token> {
        if self.line == 0 {
            self.advance_char();
            self.line += 1;
        }
        self.skip_space();
        Some(match self.advance_char()? {
            b'\n' => Token::NewLine,
            b':' => Token::Colon,
            b';' => {
                while self.nextchar? != b'\n' {
                    self.advance_char();
                }
                return self.next_token();
            }
            c @ (b'.' | b'a'..=b'z' | b'A'..=b'Z' | b'_') => {
                let mut id = String::new();
                id.push(c as char);
                while let Some(c) = self.nextchar {
                    match c {
                        b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'_' => {
                            id.push(c as char);
                            self.advance_char();
                        }
                        _ => break,
                    }
                }
                Token::Ident(id)
            }
            c @ b'0'..=b'9' => {
                let mut v = (c - b'0') as u32;
                if c == b'0' && self.nextchar == Some(b'b') {
                    self.advance_char();
                    while let Some(c) = self.nextchar {
                        match c {
                            b'0'..=b'1' => {
                                v = 2 * v + (c - b'0') as u32;
                                self.advance_char();
                            }
                            b'_' => {
                                self.advance_char();
                            }
                            _ => break,
                        }
                    }
                    Token::IntLit(v)
                } else if c == b'0' && self.nextchar == Some(b'x') {
                    self.advance_char();
                    while let Some(c) = self.nextchar {
                        match c {
                            b'0'..=b'9' => {
                                v = 16 * v + (c - b'0') as u32;
                                self.advance_char();
                            }
                            b'a'..=b'f' => {
                                v = 16 * v + (10 + c - b'a') as u32;
                                self.advance_char();
                            }
                            b'A'..=b'F' => {
                                v = 16 * v + (10 + c - b'A') as u32;
                                self.advance_char();
                            }
                            b'_' => {
                                self.advance_char();
                            }
                            _ => break,
                        }
                    }
                    Token::IntLit(v)
                } else {
                    while let Some(c) = self.nextchar {
                        match c {
                            b'0'..=b'9' => {
                                v = 10 * v + (c - b'0') as u32;
                                self.advance_char();
                            }
                            b'_' => {
                                self.advance_char();
                            }
                            _ => break,
                        }
                    }
                    Token::IntLit(v)
                }
            }
            b'\'' => {
                let v;
                if let Some(c) = self.advance_char() {
                    if c == b'\'' {
                        error!(self, "bad char literal")
                    } else if c == b'\\' {
                        if self.nextchar == Some(b'\'') {
                            v = b'\'';
                            self.advance_char();
                        } else {
                            let Some(v1) = self.escape_char() else {
                                error!(self, "bad escape char");
                            };
                            v = v1;
                        }
                    } else {
                        v = c;
                    }
                } else {
                    error!(self, "bad char literal");
                }
                if self.advance_char() != Some(b'\'') {
                    error!(self, "bad char literal");
                }
                Token::IntLit(v as u32)
            }
            b'"' => {
                let mut v = Vec::new();
                while let Some(c) = self.nextchar {
                    if c == b'"' {
                        break;
                    }
                    self.advance_char();
                    if c == b'\\' {
                        if self.nextchar == Some(b'"') {
                            v.push(b'"');
                            self.advance_char();
                        } else {
                            let Some(v1) = self.escape_char() else {
                                error!(self, "bad escape char");
                            };
                            v.push(v1);
                        }
                    } else {
                        v.push(c);
                    }
                }
                if self.advance_char() != Some(b'"') {
                    error!(self, "bad string literal");
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
                if self.nextchar == Some(b'<') {
                    self.advance_char();
                    Token::Shl
                } else {
                    error!(self, "bad token '<'")
                }
            }
            b'>' => {
                if self.nextchar == Some(b'>') {
                    self.advance_char();
                    Token::Shr
                } else {
                    error!(self, "bad token '>'")
                }
            }
            b'(' => Token::LParen,
            b')' => Token::RParen,
            c => error!(self, "bad token '{}'", c as char),
        })
    }
}
