--
-- PostgreSQL database dump
--

-- Dumped from database version 13.5
-- Dumped by pg_dump version 13.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: age_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.age_enum AS ENUM (
    'adult',
    'child',
    'under_three'
);


--
-- Name: content_section; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_section AS ENUM (
    'invitation',
    'rsvp',
    'other',
    'stylesheet',
    'accommodation'
);


--
-- Name: rsvp_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rsvp_enum AS ENUM (
    'yes',
    'no',
    'maybe'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: content; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content (
    id uuid NOT NULL,
    section public.content_section NOT NULL,
    text text NOT NULL,
    other_index integer,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    title text NOT NULL,
    slug public.citext NOT NULL
);


--
-- Name: guest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guest (
    id uuid NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    age public.age_enum DEFAULT 'adult'::public.age_enum NOT NULL,
    rsvp public.rsvp_enum,
    invite_id uuid,
    inserted_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    menu_option_id uuid,
    dietary_requirements text DEFAULT ''::text NOT NULL
);


--
-- Name: invite; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invite (
    id uuid NOT NULL,
    name text NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    extra_content public.content_section
);


--
-- Name: login; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email public.citext NOT NULL,
    confirmed_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    admin boolean DEFAULT false,
    invite_id uuid NOT NULL,
    "primary" boolean DEFAULT false
);


--
-- Name: login_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_token (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    login_id uuid NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    inserted_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


--
-- Name: menu_option; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_option (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    "order" smallint NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


--
-- Name: menu_option_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_option_order_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_option_order_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_option_order_seq OWNED BY public.menu_option."order";


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: menu_option order; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_option ALTER COLUMN "order" SET DEFAULT nextval('public.menu_option_order_seq'::regclass);


--
-- Name: content content_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_pkey PRIMARY KEY (id);


--
-- Name: login guest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT guest_pkey PRIMARY KEY (id);


--
-- Name: guest guest_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_pkey1 PRIMARY KEY (id);


--
-- Name: login_token guest_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_token
    ADD CONSTRAINT guest_tokens_pkey PRIMARY KEY (id);


--
-- Name: invite invite_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite
    ADD CONSTRAINT invite_pkey PRIMARY KEY (id);


--
-- Name: menu_option menu_option_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_option
    ADD CONSTRAINT menu_option_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: content_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX content_slug_index ON public.content USING btree (slug);


--
-- Name: guest_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX guest_email_index ON public.login USING btree (email);


--
-- Name: guest_invite_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX guest_invite_id_index ON public.guest USING btree (invite_id);


--
-- Name: guest_menu_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX guest_menu_option_id_index ON public.guest USING btree (menu_option_id);


--
-- Name: guest_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX guest_tokens_context_token_index ON public.login_token USING btree (context, token);


--
-- Name: guest_tokens_guest_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX guest_tokens_guest_id_index ON public.login_token USING btree (login_id);


--
-- Name: login_invite_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX login_invite_id_index ON public.login USING btree (invite_id);


--
-- Name: login_invite_id_primary_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX login_invite_id_primary_index ON public.login USING btree (invite_id, "primary") WHERE ("primary" = true);


--
-- Name: menu_option_order_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX menu_option_order_index ON public.menu_option USING btree ("order");


--
-- Name: guest guest_invite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.invite(id) ON DELETE CASCADE;


--
-- Name: guest guest_menu_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_menu_option_id_fkey FOREIGN KEY (menu_option_id) REFERENCES public.menu_option(id);


--
-- Name: login_token guest_tokens_guest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_token
    ADD CONSTRAINT guest_tokens_guest_id_fkey FOREIGN KEY (login_id) REFERENCES public.login(id) ON DELETE CASCADE;


--
-- Name: login login_invite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT login_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.invite(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20230322214643);
INSERT INTO public."schema_migrations" (version) VALUES (20230324144645);
INSERT INTO public."schema_migrations" (version) VALUES (20230324154709);
INSERT INTO public."schema_migrations" (version) VALUES (20230328091645);
INSERT INTO public."schema_migrations" (version) VALUES (20230328174800);
INSERT INTO public."schema_migrations" (version) VALUES (20230404130737);
INSERT INTO public."schema_migrations" (version) VALUES (20230405123240);
INSERT INTO public."schema_migrations" (version) VALUES (20230405124454);
INSERT INTO public."schema_migrations" (version) VALUES (20230415170419);
INSERT INTO public."schema_migrations" (version) VALUES (20230608065944);
INSERT INTO public."schema_migrations" (version) VALUES (20230612121215);
INSERT INTO public."schema_migrations" (version) VALUES (20230613202844);
INSERT INTO public."schema_migrations" (version) VALUES (20230614202355);
INSERT INTO public."schema_migrations" (version) VALUES (20230614205044);
