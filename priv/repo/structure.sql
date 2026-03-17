--
-- PostgreSQL database dump
--

\restrict dvzdWAHS9fFYjTeS0vRCoRClxVNAe1WQDMAurVqQzXqQ6rC48DNZjFZrprm7j8a

-- Dumped from database version 14.20 (Debian 14.20-1.pgdg13+1)
-- Dumped by pg_dump version 14.20 (Debian 14.20-1.pgdg13+1)

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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_pages (
    id bigint NOT NULL,
    name public.citext NOT NULL,
    locale character varying(255) NOT NULL,
    campaign_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    org_id bigint NOT NULL,
    delivery boolean DEFAULT true NOT NULL,
    extra_supporters integer DEFAULT 0 NOT NULL,
    thank_you_template character varying(255),
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    live boolean DEFAULT false NOT NULL,
    supporter_confirm_template character varying(255)
);


--
-- Name: action_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_pages_id_seq OWNED BY public.action_pages.id;


--
-- Name: actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actions (
    id bigint NOT NULL,
    ref bytea,
    supporter_id bigint,
    action_type character varying(255) NOT NULL,
    campaign_id bigint,
    action_page_id bigint NOT NULL,
    source_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    processing_status integer DEFAULT 0 NOT NULL,
    with_consent boolean DEFAULT false NOT NULL,
    fields jsonb DEFAULT '{}'::jsonb NOT NULL,
    testing boolean DEFAULT false NOT NULL,
    CONSTRAINT max_fields_size CHECK ((pg_column_size(fields) <= 5120))
);


--
-- Name: actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.actions_id_seq OWNED BY public.actions.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id uuid NOT NULL,
    actor_id character varying(255) NOT NULL,
    resource character varying(255) NOT NULL,
    resource_id character varying(255) NOT NULL,
    changeset jsonb NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id bigint NOT NULL,
    name public.citext NOT NULL,
    title character varying(255) NOT NULL,
    org_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    force_delivery boolean DEFAULT false NOT NULL,
    external_id integer,
    public_actions character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    contact_schema integer DEFAULT 0 NOT NULL,
    transient_actions character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    supporter_confirm boolean DEFAULT false NOT NULL,
    supporter_confirm_template character varying(255),
    start_date date,
    end_date date
);


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaigns_id_seq OWNED BY public.campaigns.id;


--
-- Name: confirms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.confirms (
    id bigint NOT NULL,
    operation integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer,
    email character varying(255),
    code character varying(255) NOT NULL,
    charges integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    message text,
    creator_id bigint
);


--
-- Name: confirms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.confirms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: confirms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.confirms_id_seq OWNED BY public.confirms.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    public_key_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    payload bytea,
    crypto_nonce bytea,
    supporter_id bigint NOT NULL,
    sign_key_id bigint,
    communication_consent boolean,
    communication_scopes character varying(255)[],
    delivery_consent boolean DEFAULT false NOT NULL,
    org_id bigint
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.donations (
    id bigint NOT NULL,
    schema integer,
    payload jsonb NOT NULL,
    amount integer NOT NULL,
    currency character(3) NOT NULL,
    action_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    frequency_unit integer DEFAULT 0 NOT NULL
);


--
-- Name: donations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.donations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.donations_id_seq OWNED BY public.donations.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_templates (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    locale character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    html text NOT NULL,
    text text,
    org_id bigint NOT NULL
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_templates_id_seq OWNED BY public.email_templates.id;


--
-- Name: message_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_contents (
    id bigint NOT NULL,
    subject text DEFAULT ''::text NOT NULL,
    body text DEFAULT ''::text NOT NULL
);


--
-- Name: message_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_contents_id_seq OWNED BY public.message_contents.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    action_id bigint NOT NULL,
    message_content_id bigint NOT NULL,
    target_id uuid NOT NULL,
    delivered boolean DEFAULT false NOT NULL,
    sent boolean DEFAULT false NOT NULL,
    opened boolean DEFAULT false NOT NULL,
    clicked boolean DEFAULT false NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    dupe_rank integer,
    files character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: mtt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mtt (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    start_at timestamp(0) without time zone NOT NULL,
    end_at timestamp(0) without time zone NOT NULL,
    stats jsonb DEFAULT '{}'::jsonb NOT NULL,
    message_template character varying(255),
    test_email character varying(255),
    max_emails_per_hour integer,
    timezone character varying(255) DEFAULT 'Etc/UTC'::character varying NOT NULL,
    cc_contacts character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    cc_sender boolean DEFAULT false NOT NULL,
    drip_delivery boolean DEFAULT true
);


--
-- Name: mtt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mtt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mtt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mtt_id_seq OWNED BY public.mtt.id;


--
-- Name: orgs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orgs (
    id bigint NOT NULL,
    name public.citext NOT NULL,
    title character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    custom_supporter_confirm boolean DEFAULT false NOT NULL,
    custom_action_confirm boolean DEFAULT false NOT NULL,
    custom_action_deliver boolean DEFAULT false NOT NULL,
    contact_schema integer DEFAULT 0 NOT NULL,
    email_backend_id bigint,
    email_from character varying(255),
    supporter_confirm boolean DEFAULT false NOT NULL,
    supporter_confirm_template character varying(255),
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    high_security boolean DEFAULT false NOT NULL,
    action_schema_version smallint DEFAULT 2 NOT NULL,
    event_backend_id bigint,
    custom_event_deliver boolean DEFAULT false NOT NULL,
    doi_thank_you boolean DEFAULT false NOT NULL,
    storage_backend_id bigint,
    detail_backend_id bigint,
    push_backend_id bigint,
    reply_enabled boolean DEFAULT true
);


--
-- Name: orgs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orgs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orgs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orgs_id_seq OWNED BY public.orgs.id;


--
-- Name: public_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.public_keys (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    org_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    public bytea,
    private bytea,
    active boolean DEFAULT false NOT NULL,
    expired boolean DEFAULT false NOT NULL
);


--
-- Name: public_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.public_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.public_keys_id_seq OWNED BY public.public_keys.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id bigint NOT NULL,
    "user" character varying(255) DEFAULT ''::character varying NOT NULL,
    password character varying(255) DEFAULT ''::character varying NOT NULL,
    host character varying(255) DEFAULT ''::character varying NOT NULL,
    path character varying(255),
    name character varying(255) NOT NULL,
    org_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: supporters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supporters (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    action_page_id bigint NOT NULL,
    source_id bigint,
    fingerprint bytea NOT NULL,
    first_name character varying(255),
    email character varying(255),
    processing_status integer DEFAULT 0 NOT NULL,
    area character varying(32),
    email_status smallint DEFAULT 0 NOT NULL,
    email_status_changed timestamp(0) without time zone,
    last_name character varying(255),
    address character varying(255),
    dupe_rank integer
);


--
-- Name: signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.signatures_id_seq OWNED BY public.supporters.id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources (
    id bigint NOT NULL,
    source character varying(255) NOT NULL,
    medium character varying(255) NOT NULL,
    campaign character varying(255) NOT NULL,
    content character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    location character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sources_id_seq OWNED BY public.sources.id;


--
-- Name: staffers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staffers (
    id bigint NOT NULL,
    perms integer DEFAULT 0 NOT NULL,
    org_id bigint NOT NULL,
    user_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    last_signin_at timestamp(0) without time zone
);


--
-- Name: staffers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staffers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staffers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staffers_id_seq OWNED BY public.staffers.id;


--
-- Name: target_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.target_emails (
    id bigint NOT NULL,
    email character varying(255),
    target_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    email_status smallint DEFAULT 0 NOT NULL,
    error character varying(255)
);


--
-- Name: target_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.target_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: target_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.target_emails_id_seq OWNED BY public.target_emails.id;


--
-- Name: targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.targets (
    id uuid NOT NULL,
    external_id character varying(255) NOT NULL,
    area character varying(255),
    name character varying(255),
    fields jsonb DEFAULT '{}'::jsonb NOT NULL,
    campaign_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    locale character varying(255),
    CONSTRAINT max_fields_size CHECK ((pg_column_size(fields) <= 5120))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    hashed_password character varying(255) NOT NULL,
    confirmed_at timestamp(0) without time zone,
    perms integer DEFAULT 0 NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    picture_url text,
    job_title text,
    phone text,
    external_id character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_tokens_id_seq OWNED BY public.users_tokens.id;


--
-- Name: action_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_pages ALTER COLUMN id SET DEFAULT nextval('public.action_pages_id_seq'::regclass);


--
-- Name: actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions ALTER COLUMN id SET DEFAULT nextval('public.actions_id_seq'::regclass);


--
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN id SET DEFAULT nextval('public.campaigns_id_seq'::regclass);


--
-- Name: confirms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confirms ALTER COLUMN id SET DEFAULT nextval('public.confirms_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: donations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations ALTER COLUMN id SET DEFAULT nextval('public.donations_id_seq'::regclass);


--
-- Name: email_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates ALTER COLUMN id SET DEFAULT nextval('public.email_templates_id_seq'::regclass);


--
-- Name: message_contents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_contents ALTER COLUMN id SET DEFAULT nextval('public.message_contents_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: mtt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mtt ALTER COLUMN id SET DEFAULT nextval('public.mtt_id_seq'::regclass);


--
-- Name: orgs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs ALTER COLUMN id SET DEFAULT nextval('public.orgs_id_seq'::regclass);


--
-- Name: public_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_keys ALTER COLUMN id SET DEFAULT nextval('public.public_keys_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ALTER COLUMN id SET DEFAULT nextval('public.sources_id_seq'::regclass);


--
-- Name: staffers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staffers ALTER COLUMN id SET DEFAULT nextval('public.staffers_id_seq'::regclass);


--
-- Name: supporters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supporters ALTER COLUMN id SET DEFAULT nextval('public.signatures_id_seq'::regclass);


--
-- Name: target_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_emails ALTER COLUMN id SET DEFAULT nextval('public.target_emails_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens ALTER COLUMN id SET DEFAULT nextval('public.users_tokens_id_seq'::regclass);


--
-- Name: action_pages action_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_pages
    ADD CONSTRAINT action_pages_pkey PRIMARY KEY (id);


--
-- Name: actions actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: confirms confirms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confirms
    ADD CONSTRAINT confirms_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: message_contents message_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_contents
    ADD CONSTRAINT message_contents_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: mtt mtt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mtt
    ADD CONSTRAINT mtt_pkey PRIMARY KEY (id);


--
-- Name: orgs orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (id);


--
-- Name: public_keys public_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_keys
    ADD CONSTRAINT public_keys_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: staffers staffers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staffers
    ADD CONSTRAINT staffers_pkey PRIMARY KEY (id);


--
-- Name: supporters supporters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supporters
    ADD CONSTRAINT supporters_pkey PRIMARY KEY (id);


--
-- Name: target_emails target_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_emails
    ADD CONSTRAINT target_emails_pkey PRIMARY KEY (id);


--
-- Name: targets targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: action_pages_campaign_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX action_pages_campaign_id_index ON public.action_pages USING btree (campaign_id);


--
-- Name: action_pages_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX action_pages_name_index ON public.action_pages USING btree (name);


--
-- Name: actions_action_page_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_action_page_id_index ON public.actions USING btree (action_page_id);


--
-- Name: actions_action_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_action_type_index ON public.actions USING btree (action_type);


--
-- Name: actions_campaign_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_campaign_id_index ON public.actions USING btree (campaign_id);


--
-- Name: actions_partial_processing_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_partial_processing_status_index ON public.actions USING btree (supporter_id, action_page_id, campaign_id) WHERE (processing_status = ANY (ARRAY[3, 4]));


--
-- Name: actions_partial_status_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_partial_status_inserted_at_index ON public.actions USING btree (processing_status, inserted_at) WHERE testing;


--
-- Name: actions_processing_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_processing_status_index ON public.actions USING btree (processing_status);


--
-- Name: actions_ref_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_ref_index ON public.actions USING btree (ref);


--
-- Name: actions_supporter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actions_supporter_id_index ON public.actions USING btree (supporter_id);


--
-- Name: campaigns_end_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_end_date_index ON public.campaigns USING btree (end_date);


--
-- Name: campaigns_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX campaigns_name_index ON public.campaigns USING btree (name);


--
-- Name: campaigns_org_id_external_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX campaigns_org_id_external_id_index ON public.campaigns USING btree (org_id, external_id);


--
-- Name: campaigns_start_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_start_date_index ON public.campaigns USING btree (start_date);


--
-- Name: confirms_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX confirms_code_index ON public.confirms USING btree (code);


--
-- Name: contacts_org_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_org_id_index ON public.contacts USING btree (org_id);


--
-- Name: contacts_supporter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_supporter_id_index ON public.contacts USING btree (supporter_id);


--
-- Name: donations_action_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX donations_action_id_index ON public.donations USING btree (action_id);


--
-- Name: email_templates_org_id_name_locale_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX email_templates_org_id_name_locale_index ON public.email_templates USING btree (org_id, name, locale);


--
-- Name: messages_partial_action_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_partial_action_index ON public.messages USING btree (action_id);


--
-- Name: messages_target_id_action_id_dupe_rank_sent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_target_id_action_id_dupe_rank_sent_index ON public.messages USING btree (target_id, action_id, dupe_rank, sent);


--
-- Name: orgs_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX orgs_name_index ON public.orgs USING btree (name);


--
-- Name: partial_inserted_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX partial_inserted_at_id_index ON public.actions USING btree (id, inserted_at) WHERE (processing_status = ANY (ARRAY[0, 3]));


--
-- Name: public_keys_org_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX public_keys_org_id_index ON public.public_keys USING btree (org_id);


--
-- Name: services_org_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_org_id_index ON public.services USING btree (org_id);


--
-- Name: sources_source_medium_campaign_content_location_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_source_medium_campaign_content_location_index ON public.sources USING btree (source, medium, campaign, content, location);


--
-- Name: staffers_org_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX staffers_org_id_user_id_index ON public.staffers USING btree (org_id, user_id);


--
-- Name: supporters_action_page_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supporters_action_page_id_index ON public.supporters USING btree (action_page_id);


--
-- Name: supporters_campaign_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supporters_campaign_id_index ON public.supporters USING btree (campaign_id);


--
-- Name: supporters_dupe_rank_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supporters_dupe_rank_index ON public.supporters USING btree (dupe_rank);


--
-- Name: supporters_fingerprint_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supporters_fingerprint_index ON public.supporters USING btree (fingerprint);


--
-- Name: supporters_processing_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supporters_processing_status_index ON public.supporters USING btree (processing_status);


--
-- Name: target_emails_target_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX target_emails_target_id_index ON public.target_emails USING btree (target_id);


--
-- Name: targets_external_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX targets_external_id_index ON public.targets USING btree (external_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_external_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_external_id_index ON public.users USING btree (external_id);


--
-- Name: users_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tokens_context_token_index ON public.users_tokens USING btree (context, token);


--
-- Name: users_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_tokens_user_id_index ON public.users_tokens USING btree (user_id);


--
-- Name: action_pages action_pages_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_pages
    ADD CONSTRAINT action_pages_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE RESTRICT;


--
-- Name: action_pages action_pages_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_pages
    ADD CONSTRAINT action_pages_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE RESTRICT;


--
-- Name: actions actions_action_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_action_page_id_fkey FOREIGN KEY (action_page_id) REFERENCES public.action_pages(id) ON DELETE RESTRICT;


--
-- Name: actions actions_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: actions actions_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE SET NULL;


--
-- Name: actions actions_supporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_supporter_id_fkey FOREIGN KEY (supporter_id) REFERENCES public.supporters(id) ON DELETE CASCADE;


--
-- Name: campaigns campaigns_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE SET NULL;


--
-- Name: confirms confirms_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confirms
    ADD CONSTRAINT confirms_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: contacts contacts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE SET NULL;


--
-- Name: contacts contacts_public_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_public_key_id_fkey FOREIGN KEY (public_key_id) REFERENCES public.public_keys(id);


--
-- Name: contacts contacts_sign_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_sign_key_id_fkey FOREIGN KEY (sign_key_id) REFERENCES public.public_keys(id);


--
-- Name: contacts contacts_supporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_supporter_id_fkey FOREIGN KEY (supporter_id) REFERENCES public.supporters(id) ON DELETE CASCADE;


--
-- Name: donations donations_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.actions(id) ON DELETE CASCADE;


--
-- Name: email_templates email_templates_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE CASCADE;


--
-- Name: messages messages_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.actions(id) ON DELETE CASCADE;


--
-- Name: messages messages_message_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_message_content_id_fkey FOREIGN KEY (message_content_id) REFERENCES public.message_contents(id) ON DELETE CASCADE;


--
-- Name: messages messages_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id) ON DELETE RESTRICT;


--
-- Name: mtt mtt_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mtt
    ADD CONSTRAINT mtt_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: orgs orgs_detail_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_detail_backend_id_fkey FOREIGN KEY (detail_backend_id) REFERENCES public.services(id) ON DELETE SET NULL;


--
-- Name: orgs orgs_email_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_email_backend_id_fkey FOREIGN KEY (email_backend_id) REFERENCES public.services(id) ON DELETE SET NULL;


--
-- Name: orgs orgs_event_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_event_backend_id_fkey FOREIGN KEY (event_backend_id) REFERENCES public.services(id) ON DELETE SET NULL;


--
-- Name: orgs orgs_push_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_push_backend_id_fkey FOREIGN KEY (push_backend_id) REFERENCES public.services(id) ON DELETE SET NULL;


--
-- Name: orgs orgs_storage_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_storage_backend_id_fkey FOREIGN KEY (storage_backend_id) REFERENCES public.services(id) ON DELETE SET NULL;


--
-- Name: public_keys public_keys_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_keys
    ADD CONSTRAINT public_keys_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE CASCADE;


--
-- Name: services services_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE CASCADE;


--
-- Name: staffers staffers_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staffers
    ADD CONSTRAINT staffers_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON DELETE CASCADE;


--
-- Name: staffers staffers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staffers
    ADD CONSTRAINT staffers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: supporters supporters_action_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supporters
    ADD CONSTRAINT supporters_action_page_id_fkey FOREIGN KEY (action_page_id) REFERENCES public.action_pages(id) ON DELETE RESTRICT;


--
-- Name: supporters supporters_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supporters
    ADD CONSTRAINT supporters_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE RESTRICT;


--
-- Name: supporters supporters_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supporters
    ADD CONSTRAINT supporters_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE SET NULL;


--
-- Name: target_emails target_emails_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_emails
    ADD CONSTRAINT target_emails_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id) ON DELETE CASCADE;


--
-- Name: targets targets_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict dvzdWAHS9fFYjTeS0vRCoRClxVNAe1WQDMAurVqQzXqQ6rC48DNZjFZrprm7j8a

--
-- PostgreSQL database dump
--

\restrict dHMOh59biE00I69W4HfunEKNacwE8VvgW2PDuuy1K9azmgnnoFQoUQt6XGONdag

-- Dumped from database version 14.20 (Debian 14.20-1.pgdg13+1)
-- Dumped by pg_dump version 14.20 (Debian 14.20-1.pgdg13+1)

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
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (version, inserted_at) FROM stdin;
20200216155803	2026-03-16 14:37:19
20200216160005	2026-03-16 14:37:19
20200216160617	2026-03-16 14:37:19
20200216162702	2026-03-16 14:37:19
20200216172338	2026-03-16 14:37:19
20200216172508	2026-03-16 14:37:19
20200216173621	2026-03-16 14:37:19
20200216174648	2026-03-16 14:37:19
20200217082940	2026-03-16 14:37:19
20200217083232	2026-03-16 14:37:19
20200217084440	2026-03-16 14:37:19
20200217084727	2026-03-16 14:37:19
20200217145247	2026-03-16 14:37:19
20200217170621	2026-03-16 14:37:19
20200219222933	2026-03-16 14:37:19
20200220110057	2026-03-16 14:37:19
20200220222911	2026-03-16 14:37:19
20200303082509	2026-03-16 14:37:19
20200303084536	2026-03-16 14:37:19
20200309145751	2026-03-16 14:37:19
20200323112323	2026-03-16 14:37:19
20200323152226	2026-03-16 14:37:19
20200408151752	2026-03-16 14:37:19
20200410175531	2026-03-16 14:37:19
20200417143834	2026-03-16 14:37:19
20200513123032	2026-03-16 14:37:19
20200513215935	2026-03-16 14:37:19
20200514214934	2026-03-16 14:37:19
20200517200824	2026-03-16 14:37:19
20200517215824	2026-03-16 14:37:19
20200518074529	2026-03-16 14:37:19
20200518110458	2026-03-16 14:37:19
20200518182717	2026-03-16 14:37:19
20200527075056	2026-03-16 14:37:19
20200530172025	2026-03-16 14:37:19
20200602220302	2026-03-16 14:37:19
20200603134359	2026-03-16 14:37:19
20200605162822	2026-03-16 14:37:19
20200608124555	2026-03-16 14:37:19
20200609132552	2026-03-16 14:37:19
20200609144956	2026-03-16 14:37:19
20200615080332	2026-03-16 14:37:19
20200615161928	2026-03-16 14:37:19
20200617203540	2026-03-16 14:37:19
20200711114921	2026-03-16 14:37:19
20200727095935	2026-03-16 14:37:19
20200727103905	2026-03-16 14:37:19
20200727212540	2026-03-16 14:37:19
20200804125443	2026-03-16 14:37:19
20200824094510	2026-03-16 14:37:19
20200824113349	2026-03-16 14:37:19
20200911083012	2026-03-16 14:37:19
20200918091844	2026-03-16 14:37:19
20201019135201	2026-03-16 14:37:19
20201019135336	2026-03-16 14:37:19
20201025182200	2026-03-16 14:37:19
20201104164703	2026-03-16 14:37:19
20201120163019	2026-03-16 14:37:19
20201207134031	2026-03-16 14:37:19
20210122114655	2026-03-16 14:37:19
20210122121943	2026-03-16 14:37:19
20210301182312	2026-03-16 14:37:19
20210304174947	2026-03-16 14:37:19
20210331084454	2026-03-16 14:37:19
20210408084322	2026-03-16 14:37:19
20210518092615	2026-03-16 14:37:19
20210527154054	2026-03-16 14:37:19
20210530144413	2026-03-16 14:37:19
20210530194531	2026-03-16 14:37:19
20210616105259	2026-03-16 14:37:19
20210721104452	2026-03-16 14:37:19
20210802060718	2026-03-16 14:37:19
20210807100051	2026-03-16 14:37:19
20210823161059	2026-03-16 14:37:19
20210829194238	2026-03-16 14:37:19
20210922174521	2026-03-16 14:37:19
20210924143116	2026-03-16 14:37:19
20210929073932	2026-03-16 14:37:19
20210929152407	2026-03-16 14:37:19
20211027070617	2026-03-16 14:37:19
20211109120438	2026-03-16 14:37:19
20211109120812	2026-03-16 14:37:19
20211109134038	2026-03-16 14:37:19
20211112212140	2026-03-16 14:37:19
20211116124743	2026-03-16 14:37:19
20211119150751	2026-03-16 14:37:19
20211122182219	2026-03-16 14:37:19
20211206093946	2026-03-16 14:37:20
20211213100558	2026-03-16 14:37:20
20211214175814	2026-03-16 14:37:20
20211220212605	2026-03-16 14:37:20
20211221110910	2026-03-16 14:37:20
20211222205257	2026-03-16 14:37:20
20220103165519	2026-03-16 14:37:20
20220104093448	2026-03-16 14:37:20
20220110091050	2026-03-16 14:37:20
20220111225427	2026-03-16 14:37:20
20220112200625	2026-03-16 14:37:20
20220124174655	2026-03-16 14:37:20
20220127202400	2026-03-16 14:37:20
20220128231339	2026-03-16 14:37:20
20220130212834	2026-03-16 14:37:20
20220131114346	2026-03-16 14:37:20
20220201191156	2026-03-16 14:37:20
20220204225820	2026-03-16 14:37:20
20220205182715	2026-03-16 14:37:20
20220206233831	2026-03-16 14:37:20
20220221173944	2026-03-16 14:37:20
20220222173105	2026-03-16 14:37:20
20220307120321	2026-03-16 14:37:20
20220314121517	2026-03-16 14:37:20
20220328200407	2026-03-16 14:37:20
20220411181114	2026-03-16 14:37:20
20220415130710	2026-03-16 14:37:20
20220419122620	2026-03-16 14:37:20
20220510190049	2026-03-16 14:37:20
20220603104555	2026-03-16 14:37:20
20220606075651	2026-03-16 14:37:20
20220607065933	2026-03-16 14:37:20
20220614140633	2026-03-16 14:37:20
20220810062528	2026-03-16 14:37:20
20220815102248	2026-03-16 14:37:20
20220830105140	2026-03-16 14:37:20
20221019154522	2026-03-16 14:37:20
20221125105915	2026-03-16 14:37:20
20230510074416	2026-03-16 14:37:20
20230802114854	2026-03-16 14:37:20
20240606100400	2026-03-16 14:37:20
20250520205903	2026-03-16 14:37:20
20250708011041	2026-03-16 14:37:20
20250716132947	2026-03-16 14:37:20
20250728131601	2026-03-16 14:37:20
20250728132318	2026-03-16 14:37:20
20250812130145	2026-03-16 14:37:20
20250904150640	2026-03-16 14:37:20
20251002133727	2026-03-16 14:37:20
20251102174344	2026-03-16 14:37:20
20251102174912	2026-03-16 14:37:20
20251106145422	2026-03-16 14:37:20
20251106205011	2026-03-16 14:37:20
20251107220738	2026-03-16 14:37:20
20260207162539	2026-03-16 14:37:20
\.


--
-- PostgreSQL database dump complete
--

\unrestrict dHMOh59biE00I69W4HfunEKNacwE8VvgW2PDuuy1K9azmgnnoFQoUQt6XGONdag

