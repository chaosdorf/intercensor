#!/usr/bin/env python
from flask import Flask, session, redirect, url_for, request, render_template, g
from functools import wraps
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm.exc import NoResultFound
import bcrypt

app = Flask(__name__)
app.config["DEBUG"] = True
app.secret_key = "b6SQepLi1RcujY6vLRhZBT2HcC6iNDbXdjSwi5F+r5Hllu4KTkhvl8PptqJU6srrB7g="

Base = declarative_base()

class Challenge(object):
    def __init__(self, name):
        self.name = name

challenge_data = {
    "01recordbreaker": Challenge("Record Breaker"),
    "02anondelivers": Challenge("Anon Delivers"),
    "99shutdown": Challenge("Shut Down"),
}
        
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    passwordhash = Column(String)

    def __init__(self, name, password):
        self.name = name
        self.passwordhash = bcrypt.hashpw(password, bcrypt.gensalt())

    def check_password(self, password):
        return bcrypt.hashpw(password, self.passwordhash) == self.passwordhash

    def current_challenge(self):
        try:
            return sa_session.query(UserChallenge).filter_by(user_id=self.id, status="playing").one().challenge
        except NoResultFound:
            return None

class UserChallenge(Base):
    __tablename__ = "user_challenges"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    challenge_id = Column(String, primary_key=True)
    status = Column(Enum("open", "done", "playing"))

    def _challenge_get(self):
        if self.challenge_id:
            return challenge_data[self.challenge_id]
        else:
            return None

    challenge = property(_challenge_get)

engine = create_engine("sqlite:///intercensor.db", echo=True)
metadata = Base.metadata
metadata.create_all(bind=engine)
sa_session = sessionmaker(bind=engine)()

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' in session:
            return f(*args, **kwargs)
        else:
            return redirect(url_for("login"))

    return decorated_function


@app.route("/")
def index():
    if session.get("user_id"):
        return redirect(url_for("dashboard"))
    else:
        return redirect(url_for("login"))

@app.route("/login", methods=["POST", "GET"])
def login():
    error = None
    if request.method == "POST":
        try:
            try:
                user = sa_session.query(User).filter_by(name=request.form["username"]).one()
            except NoResultFound:
                error = "Authentication failed"
            if user.check_password(request.form["password"]):
                session["user_id"] = user.id
                return redirect(url_for("dashboard"))
            else:
                error = "Authentication failed"
        except KeyError:
            # form data incomplete
            error = "Please fill out all form fields"
            pass

    return render_template("login", error=error)

@app.route("/register")
def register():
    return render_template("register", error=None)

@app.route("/about")
def about():
    return "About"

@app.route("/challenges")
@login_required
def challenges():
    return "Challenges"

@app.route("/logout")
@login_required
def logout():
    session.clear()
    return redirect(url_for("login"))

@app.route("/dashboard")
@login_required
def dashboard():
    user = sa_session.query(User).one()
    return render_template("dashboard", current_challenge=user.current_challenge())

if __name__ == "__main__":
    app.run()
