import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/http
import gleam/http/response
import gleam/int
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import notion_client/internal/utils
import notion_client/schema

pub type UpdateAblockRequest {
  UpdateAblockRequest(paragraph: Option(AnonF076b6f9))
}

pub type AppendBlockChildrenRequest {
  AppendBlockChildrenRequest(children: Option(List(Anon0413a8c6)))
}

pub type AddCommentToPageRequest {
  AddCommentToPageRequest(
    parent: Option(AnonA98b8bc6),
    rich_text: Option(List(AnonC7f73fca)),
  )
}

pub type CreateAdatabaseRequest {
  CreateAdatabaseRequest(
    parent: Option(AnonC5693729),
    properties: Option(Anon3722994e),
    title: Option(List(Anon6bec251d)),
  )
}

pub type UpdateAdatabaseRequest {
  UpdateAdatabaseRequest(
    properties: Option(Anon6175b337),
    title: Option(List(Anon7a994aba)),
  )
}

pub type QueryAdatabaseRequest {
  QueryAdatabaseRequest(filter: Option(AnonF6e3d490))
}

pub type CreateApageRequest {
  CreateApageRequest(
    children: Option(List(AnonC20d9618)),
    parent: Option(AnonF9e4288c),
    properties: Option(Anon79ac01f2),
  )
}

pub type UpdatePagePropertiesRequest {
  UpdatePagePropertiesRequest(archived: Option(Bool))
}

pub type SearchRequest {
  SearchRequest(query: Option(String), sort: Option(Anon01bf2ac9))
}

pub type RetrieveAuserResponse {
  RetrieveAuserResponse(
    avatar_url: Option(String),
    id: Option(String),
    name: Option(String),
    object: Option(String),
    person: Option(Anon8818ae5d),
    type_: Option(String),
  )
}

pub type RetrieveYourTokenSbotUserResponse {
  RetrieveYourTokenSbotUserResponse(
    avatar_url: Option(String),
    bot: Option(AnonFec5f02c),
    id: Option(String),
    name: Option(String),
    object: Option(String),
    type_: Option(String),
  )
}

pub type ListAllUsersResponse {
  ListAllUsersResponse(
    has_more: Option(Bool),
    next_cursor: Option(String),
    object: Option(String),
    results: Option(List(Anon84b72b7f)),
  )
}

pub type SearchResponse {
  SearchResponse(
    has_more: Option(Bool),
    next_cursor: Option(String),
    object: Option(String),
    results: Option(List(AnonF122065e)),
  )
}

pub type RetrieveApagePropertyItemResponse {
  RetrieveApagePropertyItemResponse(
    object: Option(String),
    select: Option(Anon1a5d0865),
    type_: Option(String),
  )
}

pub type UpdatePagePropertiesResponse {
  UpdatePagePropertiesResponse(
    archived: Option(Bool),
    child_page: Option(Anon689d2bb8),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    has_children: Option(Bool),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonFa44d465),
    properties: Option(Anon56b0c7e7),
    type_: Option(String),
  )
}

pub type RetrieveApageResponse {
  RetrieveApageResponse(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(Anon38aba9ed),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonC5693729),
    properties: Option(Anon9e677ad4),
    url: Option(String),
  )
}

pub type CreateApageResponse {
  CreateApageResponse(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(String),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonFa44d465),
    properties: Option(AnonF8bd2b0a),
    url: Option(String),
  )
}

pub type QueryAdatabaseResponse {
  QueryAdatabaseResponse(
    has_more: Option(Bool),
    next_cursor: Option(String),
    object: Option(String),
    results: Option(List(Anon638ebbba)),
  )
}

pub type UpdateAdatabaseResponse {
  UpdateAdatabaseResponse(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(String),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonC5693729),
    properties: Option(AnonBcf7bc9b),
    title: Option(List(Anon6547fe66)),
    url: Option(String),
  )
}

pub type RetrieveAdatabaseResponse {
  RetrieveAdatabaseResponse(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(String),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonC5693729),
    properties: Option(AnonE40599ac),
    title: Option(List(Anon6547fe66)),
    url: Option(String),
  )
}

pub type CreateAdatabaseResponse {
  CreateAdatabaseResponse(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(String),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonC5693729),
    properties: Option(AnonB6b66157),
    title: Option(List(Anon6547fe66)),
    url: Option(String),
  )
}

pub type AddCommentToPageResponse {
  AddCommentToPageResponse(
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    discussion_id: Option(String),
    id: Option(String),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(Anon0bc52013),
    rich_text: Option(List(Anon6547fe66)),
  )
}

pub type RetrieveCommentsResponse {
  RetrieveCommentsResponse(
    comment: Option(Nil),
    has_more: Option(Bool),
    next_cursor: Option(String),
    object: Option(String),
    results: Option(List(Anon2d4a475d)),
    type_: Option(String),
  )
}

pub type AppendBlockChildrenResponse {
  AppendBlockChildrenResponse(
    child_page: Option(Anon689d2bb8),
    created_time: Option(String),
    has_children: Option(Bool),
    id: Option(String),
    last_edited_time: Option(String),
    object: Option(String),
    type_: Option(String),
  )
}

pub type RetrieveBlockChildrenResponse {
  RetrieveBlockChildrenResponse(
    has_more: Option(Bool),
    next_cursor: Option(String),
    object: Option(String),
    results: Option(List(AnonE3efa372)),
  )
}

pub type UpdateAblockResponse {
  UpdateAblockResponse(
    created_time: Option(String),
    has_children: Option(Bool),
    id: Option(String),
    last_edited_time: Option(String),
    object: Option(String),
    paragraph: Option(AnonB34b8240),
    type_: Option(String),
  )
}

pub type DeleteAblockResponse {
  DeleteAblockResponse(
    archived: Option(Bool),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    has_children: Option(Bool),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    paragraph: Option(AnonB34b8240),
    type_: Option(String),
  )
}

pub type RetrieveAblockResponse {
  RetrieveAblockResponse(
    created_time: Option(String),
    has_children: Option(Bool),
    id: Option(String),
    last_edited_time: Option(String),
    object: Option(String),
    paragraph: Option(AnonB34b8240),
    type_: Option(String),
  )
}

pub type Anon41cfe9c2 {
  Anon41cfe9c2(
    bold: Option(Bool),
    code: Option(Bool),
    color: Option(String),
    italic: Option(Bool),
    strikethrough: Option(Bool),
    underline: Option(Bool),
  )
}

pub type AnonCc655f07 {
  AnonCc655f07(url: Option(String))
}

pub type AnonDedd9608 {
  AnonDedd9608(content: Option(String), link: Option(AnonCc655f07))
}

pub type Anon6547fe66 {
  Anon6547fe66(
    annotations: Option(Anon41cfe9c2),
    href: Option(String),
    plain_text: Option(String),
    text: Option(AnonDedd9608),
    type_: Option(String),
  )
}

pub type AnonB34b8240 {
  AnonB34b8240(text: Option(List(Anon6547fe66)))
}

pub type AnonC5650f42 {
  AnonC5650f42(id: Option(String), object: Option(String))
}

pub type AnonD43b5a15 {
  AnonD43b5a15(content: Option(String))
}

pub type Anon1b577071 {
  Anon1b577071(text: Option(AnonD43b5a15), type_: Option(String))
}

pub type AnonF076b6f9 {
  AnonF076b6f9(text: Option(List(Anon1b577071)))
}

pub type AnonE3efa372 {
  AnonE3efa372(
    created_time: Option(String),
    has_children: Option(Bool),
    id: Option(String),
    last_edited_time: Option(String),
    object: Option(String),
    paragraph: Option(AnonB34b8240),
    type_: Option(String),
    unsupported: Option(Nil),
  )
}

pub type AnonF000d16e {
  AnonF000d16e(content: Option(String), link: Option(AnonCc655f07))
}

pub type Anon96274cab {
  Anon96274cab(text: Option(AnonF000d16e), type_: Option(String))
}

pub type Anon15570785 {
  Anon15570785(text: Option(List(Anon96274cab)))
}

pub type Anon0413a8c6 {
  Anon0413a8c6(
    heading_2: Option(AnonF076b6f9),
    object: Option(String),
    paragraph: Option(Anon15570785),
    type_: Option(String),
  )
}

pub type Anon689d2bb8 {
  Anon689d2bb8(title: Option(String))
}

pub type Anon8882a242 {
  Anon8882a242(block_id: Option(String), type_: Option(String))
}

pub type Anon2d4a475d {
  Anon2d4a475d(
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    discussion_id: Option(String),
    id: Option(String),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(Anon8882a242),
    rich_text: Option(List(Anon6547fe66)),
  )
}

pub type AnonA98b8bc6 {
  AnonA98b8bc6(page_id: Option(String))
}

pub type Anon8d557d08 {
  Anon8d557d08(user: Option(AnonC5650f42))
}

pub type AnonC7f73fca {
  AnonC7f73fca(mention: Option(Anon8d557d08), text: Option(AnonD43b5a15))
}

pub type Anon0bc52013 {
  Anon0bc52013(
    block_id: Option(String),
    page_id: Option(String),
    type_: Option(String),
  )
}

pub type AnonC5693729 {
  AnonC5693729(page_id: Option(String), type_: Option(String))
}

pub type AnonC8c0aec2 {
  AnonC8c0aec2(people: Option(Nil))
}

pub type Anon1ded2ce6 {
  Anon1ded2ce6(rich_text: Option(Nil))
}

pub type Anon88cd52c9 {
  Anon88cd52c9(color: Option(String), name: Option(String))
}

pub type Anon9dd0af2b {
  Anon9dd0af2b(options: Option(List(Anon88cd52c9)))
}

pub type Anon4f2ef5d5 {
  Anon4f2ef5d5(select: Option(Anon9dd0af2b))
}

pub type Anon425d6e5c {
  Anon425d6e5c(checkbox: Option(Nil))
}

pub type Anon1adf7f5d {
  Anon1adf7f5d(date: Option(Nil))
}

pub type AnonC602fa17 {
  AnonC602fa17(title: Option(Nil))
}

pub type Anon7d0bf624 {
  Anon7d0bf624(files: Option(Nil))
}

pub type AnonB49d5525 {
  AnonB49d5525(format: Option(String))
}

pub type Anon6d61c900 {
  Anon6d61c900(number: Option(AnonB49d5525))
}

pub type Anon357a746a {
  Anon357a746a(multi_select: Option(Anon9dd0af2b), type_: Option(String))
}

pub type Anon3722994e {
  Anon3722994e(
    positive_1: Option(AnonC8c0aec2),
    description: Option(Anon1ded2ce6),
    food_group: Option(Anon4f2ef5d5),
    in_stock: Option(Anon425d6e5c),
    last_ordered: Option(Anon1adf7f5d),
    name: Option(AnonC602fa17),
    photo: Option(Anon7d0bf624),
    price: Option(Anon6d61c900),
    store_availability: Option(Anon357a746a),
  )
}

pub type Anon6bec251d {
  Anon6bec251d(text: Option(AnonDedd9608), type_: Option(String))
}

pub type Anon419560a7 {
  Anon419560a7(
    id: Option(String),
    name: Option(String),
    people: Option(Nil),
    type_: Option(String),
  )
}

pub type Anon5ed12ef0 {
  Anon5ed12ef0(
    id: Option(String),
    name: Option(String),
    rich_text: Option(Nil),
    type_: Option(String),
  )
}

pub type Anon1a5d0865 {
  Anon1a5d0865(color: Option(String), id: Option(String), name: Option(String))
}

pub type Anon1ac3a1b3 {
  Anon1ac3a1b3(options: Option(List(Anon1a5d0865)))
}

pub type Anon97e8db5f {
  Anon97e8db5f(
    id: Option(String),
    name: Option(String),
    select: Option(Anon1ac3a1b3),
    type_: Option(String),
  )
}

pub type Anon33d8fac3 {
  Anon33d8fac3(
    checkbox: Option(Nil),
    id: Option(String),
    name: Option(String),
    type_: Option(String),
  )
}

pub type Anon63b0ebf8 {
  Anon63b0ebf8(
    date: Option(Nil),
    id: Option(String),
    name: Option(String),
    type_: Option(String),
  )
}

pub type AnonCf985fdc {
  AnonCf985fdc(
    id: Option(String),
    name: Option(String),
    title: Option(Nil),
    type_: Option(String),
  )
}

pub type AnonBd3eeb6e {
  AnonBd3eeb6e(
    files: Option(Nil),
    id: Option(String),
    name: Option(String),
    type_: Option(String),
  )
}

pub type AnonCa26f6a6 {
  AnonCa26f6a6(
    id: Option(String),
    name: Option(String),
    number: Option(AnonB49d5525),
    type_: Option(String),
  )
}

pub type Anon283ff0af {
  Anon283ff0af(
    id: Option(String),
    multi_select: Option(Anon1ac3a1b3),
    name: Option(String),
    type_: Option(String),
  )
}

pub type AnonB6b66157 {
  AnonB6b66157(
    positive_1: Option(Anon419560a7),
    description: Option(Anon5ed12ef0),
    food_group: Option(Anon97e8db5f),
    in_stock: Option(Anon33d8fac3),
    last_ordered: Option(Anon63b0ebf8),
    name: Option(AnonCf985fdc),
    photo: Option(AnonBd3eeb6e),
    price: Option(AnonCa26f6a6),
    store_availability: Option(Anon283ff0af),
  )
}

pub type Anon484ec035 {
  Anon484ec035(
    id: Option(String),
    name: Option(String),
    type_: Option(String),
    url: Option(Nil),
  )
}

pub type AnonE40599ac {
  AnonE40599ac(
    author: Option(Anon283ff0af),
    link: Option(Anon484ec035),
    name: Option(AnonCf985fdc),
    publisher: Option(Anon97e8db5f),
    publishing__release_date: Option(Anon63b0ebf8),
    read: Option(Anon33d8fac3),
    score__5: Option(Anon97e8db5f),
    status: Option(Anon97e8db5f),
    summary: Option(Anon5ed12ef0),
    type_: Option(Anon97e8db5f),
  )
}

pub type Anon6175b337 {
  Anon6175b337(wine_pairing: Option(Anon1ded2ce6))
}

pub type Anon7a994aba {
  Anon7a994aba(text: Option(AnonD43b5a15))
}

pub type AnonBcf7bc9b {
  AnonBcf7bc9b(
    author: Option(Anon283ff0af),
    link: Option(Anon484ec035),
    name: Option(AnonCf985fdc),
    publisher: Option(Anon97e8db5f),
    publishing__release_date: Option(Anon63b0ebf8),
    read: Option(Anon33d8fac3),
    score__5: Option(Anon97e8db5f),
    status: Option(Anon97e8db5f),
    summary: Option(Anon5ed12ef0),
    type_: Option(Anon97e8db5f),
    wine_pairing: Option(Anon5ed12ef0),
  )
}

pub type Anon2795bf82 {
  Anon2795bf82(equals: Option(String))
}

pub type AnonF6e3d490 {
  AnonF6e3d490(property: Option(String), select: Option(Anon2795bf82))
}

pub type AnonFa44d465 {
  AnonFa44d465(database_id: Option(String), type_: Option(String))
}

pub type Anon161e1529 {
  Anon161e1529(
    id: Option(String),
    multi_select: Option(List(Anon1a5d0865)),
    type_: Option(String),
  )
}

pub type Anon8843700c {
  Anon8843700c(id: Option(String), type_: Option(String), url: Option(String))
}

pub type AnonAa5ae26f {
  AnonAa5ae26f(
    id: Option(String),
    title: Option(List(Anon6547fe66)),
    type_: Option(String),
  )
}

pub type AnonBfe18c29 {
  AnonBfe18c29(
    id: Option(String),
    select: Option(Anon1a5d0865),
    type_: Option(String),
  )
}

pub type Anon7dffc985 {
  Anon7dffc985(
    end: Option(String),
    start: Option(String),
    time_zone: Option(String),
  )
}

pub type Anon78adfe19 {
  Anon78adfe19(
    date: Option(Anon7dffc985),
    id: Option(String),
    type_: Option(String),
  )
}

pub type AnonCd3ace58 {
  AnonCd3ace58(
    checkbox: Option(Bool),
    id: Option(String),
    type_: Option(String),
  )
}

pub type Anon30481f82 {
  Anon30481f82(
    id: Option(String),
    select: Option(Anon1a5d0865),
    type_: Option(String),
  )
}

pub type Anon6af8e0a7 {
  Anon6af8e0a7(
    id: Option(String),
    rich_text: Option(List(Anon6547fe66)),
    type_: Option(String),
  )
}

pub type Anon858342ba {
  Anon858342ba(
    author: Option(Anon161e1529),
    link: Option(Anon8843700c),
    name: Option(AnonAa5ae26f),
    publisher: Option(AnonBfe18c29),
    publishing__release_date: Option(Anon78adfe19),
    read: Option(AnonCd3ace58),
    score__5: Option(Anon30481f82),
    status: Option(AnonBfe18c29),
    summary: Option(Anon6af8e0a7),
    type_: Option(AnonBfe18c29),
  )
}

pub type Anon638ebbba {
  Anon638ebbba(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(String),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonFa44d465),
    properties: Option(Anon858342ba),
    url: Option(String),
  )
}

pub type AnonAde1189e {
  AnonAde1189e(rich_text: Option(List(Anon1b577071)))
}

pub type AnonC20d9618 {
  AnonC20d9618(
    heading_2: Option(AnonAde1189e),
    object: Option(String),
    paragraph: Option(Anon15570785),
    type_: Option(String),
  )
}

pub type AnonF9e4288c {
  AnonF9e4288c(database_id: Option(String))
}

pub type Anon6e9b6d9d {
  Anon6e9b6d9d(title: Option(List(Anon7a994aba)))
}

pub type Anon2bd864ec {
  Anon2bd864ec(select: Option(Anon1a5d0865))
}

pub type Anon750d4b8a {
  Anon750d4b8a(end: Option(String), start: Option(String))
}

pub type Anon43b73855 {
  Anon43b73855(date: Option(Anon750d4b8a))
}

pub type Anon22c04b67 {
  Anon22c04b67(checkbox: Option(Bool))
}

pub type AnonE374b215 {
  AnonE374b215(rich_text: Option(List(Anon6547fe66)))
}

pub type Anon79ac01f2 {
  Anon79ac01f2(
    link: Option(AnonCc655f07),
    name: Option(Anon6e9b6d9d),
    publisher: Option(Anon2bd864ec),
    publishing__release_date: Option(Anon43b73855),
    read: Option(Anon22c04b67),
    score__5: Option(Anon2bd864ec),
    status: Option(Anon2bd864ec),
    summary: Option(AnonE374b215),
    type_: Option(Anon2bd864ec),
  )
}

pub type Anon53c57fa2 {
  Anon53c57fa2(
    id: Option(String),
    multi_select: Option(List(utils.Any)),
    type_: Option(String),
  )
}

pub type AnonF8bd2b0a {
  AnonF8bd2b0a(
    author: Option(Anon53c57fa2),
    link: Option(Anon8843700c),
    name: Option(AnonAa5ae26f),
    publisher: Option(AnonBfe18c29),
    publishing__release_date: Option(Anon78adfe19),
    read: Option(AnonCd3ace58),
    score__5: Option(AnonBfe18c29),
    status: Option(AnonBfe18c29),
    summary: Option(Anon6af8e0a7),
    type_: Option(AnonBfe18c29),
  )
}

pub type Anon38aba9ed {
  Anon38aba9ed(emoji: Option(String), type_: Option(String))
}

pub type Anon9e677ad4 {
  Anon9e677ad4(title: Option(AnonAa5ae26f))
}

pub type AnonD9627bc6 {
  AnonD9627bc6(
    date: Option(Anon750d4b8a),
    id: Option(String),
    type_: Option(String),
  )
}

pub type Anon56b0c7e7 {
  Anon56b0c7e7(
    author: Option(Anon161e1529),
    link: Option(Anon8843700c),
    name: Option(AnonAa5ae26f),
    publisher: Option(AnonBfe18c29),
    publishing__release_date: Option(AnonD9627bc6),
    read: Option(AnonCd3ace58),
    score__5: Option(AnonBfe18c29),
    status: Option(AnonBfe18c29),
    summary: Option(Anon6af8e0a7),
    type_: Option(AnonBfe18c29),
  )
}

pub type Anon01bf2ac9 {
  Anon01bf2ac9(direction: Option(String), timestamp: Option(String))
}

pub type Anon4d415cb6 {
  Anon4d415cb6(
    id: Option(String),
    rich_text: Option(List(utils.Any)),
    type_: Option(String),
  )
}

pub type Anon378ba014 {
  Anon378ba014(date: Option(String), id: Option(String), type_: Option(String))
}

pub type Anon9e0f6f2e {
  Anon9e0f6f2e(
    author: Option(Anon53c57fa2),
    link: Option(Anon8843700c),
    name: Option(AnonAa5ae26f),
    publisher: Option(AnonBfe18c29),
    publishing__release_date: Option(Anon78adfe19),
    read: Option(AnonCd3ace58),
    score__5: Option(AnonBfe18c29),
    status: Option(AnonBfe18c29),
    summary: Option(Anon6af8e0a7),
    type_: Option(AnonBfe18c29),
    wine_pairing: Option(Anon4d415cb6),
    date: Option(Anon378ba014),
  )
}

pub type AnonF122065e {
  AnonF122065e(
    archived: Option(Bool),
    cover: Option(String),
    created_by: Option(AnonC5650f42),
    created_time: Option(String),
    icon: Option(String),
    id: Option(String),
    last_edited_by: Option(AnonC5650f42),
    last_edited_time: Option(String),
    object: Option(String),
    parent: Option(AnonFa44d465),
    properties: Option(Anon9e0f6f2e),
    url: Option(String),
  )
}

pub type Anon2df27035 {
  Anon2df27035(type_: Option(String), workspace: Option(Bool))
}

pub type AnonFec5f02c {
  AnonFec5f02c(owner: Option(Anon2df27035))
}

pub type Anon8818ae5d {
  Anon8818ae5d(email: Option(String))
}

pub type Anon84b72b7f {
  Anon84b72b7f(
    avatar_url: Option(String),
    bot: Option(AnonFec5f02c),
    id: Option(String),
    name: Option(String),
    object: Option(String),
    person: Option(Anon8818ae5d),
    type_: Option(String),
  )
}

pub fn retrieve_auser_request(base, id) {
  let method = http.Get
  let path = "/v1/users/" <> id
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_auser_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use avatar_url <- decode.optional_field(
          "avatar_url",
          None,
          decode.optional(decode.string),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use name <- decode.optional_field(
          "name",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use person <- decode.optional_field(
          "person",
          None,
          decode.optional(anon_8818ae5d_decoder()),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveAuserResponse(
          avatar_url: avatar_url,
          id: id,
          name: name,
          object: object,
          person: person,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_your_token_sbot_user_request(base) {
  let method = http.Get
  let path = "/v1/users/me"
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_your_token_sbot_user_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use avatar_url <- decode.optional_field(
          "avatar_url",
          None,
          decode.optional(decode.string),
        )
        use bot <- decode.optional_field(
          "bot",
          None,
          decode.optional(anon_fec5f02c_decoder()),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use name <- decode.optional_field(
          "name",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveYourTokenSbotUserResponse(
          avatar_url: avatar_url,
          bot: bot,
          id: id,
          name: name,
          object: object,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn list_all_users_request(base) {
  let method = http.Get
  let path = "/v1/users"
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn list_all_users_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use has_more <- decode.optional_field(
          "has_more",
          None,
          decode.optional(decode.bool),
        )
        use next_cursor <- decode.optional_field(
          "next_cursor",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use results <- decode.optional_field(
          "results",
          None,
          decode.optional(decode.list(anon_84b72b7f_decoder())),
        )
        decode.success(ListAllUsersResponse(
          has_more: has_more,
          next_cursor: next_cursor,
          object: object,
          results: results,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn search_request(base, data: SearchRequest) {
  let method = http.Post
  let path = "/v1/search"
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #("query", json.nullable(data.query, json.string)),
        #("sort", json.nullable(data.sort, anon_01bf2ac9_encode)),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn search_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use has_more <- decode.optional_field(
          "has_more",
          None,
          decode.optional(decode.bool),
        )
        use next_cursor <- decode.optional_field(
          "next_cursor",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use results <- decode.optional_field(
          "results",
          None,
          decode.optional(decode.list(anon_f122065e_decoder())),
        )
        decode.success(SearchResponse(
          has_more: has_more,
          next_cursor: next_cursor,
          object: object,
          results: results,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_apage_property_item_request(base, page_id, property_id) {
  let method = http.Get
  let path = "/v1/pages/" <> page_id <> "/properties/" <> property_id
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_apage_property_item_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use select <- decode.optional_field(
          "select",
          None,
          decode.optional(anon_1a5d0865_decoder()),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveApagePropertyItemResponse(
          object: object,
          select: select,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn update_page_properties_request(
  base,
  id,
  data: UpdatePagePropertiesRequest,
) {
  let method = http.Patch
  let path = "/v1/pages/" <> id
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([#("archived", json.nullable(data.archived, json.bool))]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn update_page_properties_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use child_page <- decode.optional_field(
          "child_page",
          None,
          decode.optional(anon_689d2bb8_decoder()),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use has_children <- decode.optional_field(
          "has_children",
          None,
          decode.optional(decode.bool),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_fa44d465_decoder()),
        )
        use properties <- decode.optional_field(
          "properties",
          None,
          decode.optional(anon_56b0c7e7_decoder()),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(UpdatePagePropertiesResponse(
          archived: archived,
          child_page: child_page,
          created_by: created_by,
          created_time: created_time,
          has_children: has_children,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          properties: properties,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_apage_request(base, id) {
  let method = http.Get
  let path = "/v1/pages/" <> id
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_apage_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use cover <- decode.optional_field(
          "cover",
          None,
          decode.optional(decode.string),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use icon <- decode.optional_field(
          "icon",
          None,
          decode.optional(anon_38aba9ed_decoder()),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_c5693729_decoder()),
        )
        use properties <- decode.optional_field(
          "properties",
          None,
          decode.optional(anon_9e677ad4_decoder()),
        )
        use url <- decode.optional_field(
          "url",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveApageResponse(
          archived: archived,
          cover: cover,
          created_by: created_by,
          created_time: created_time,
          icon: icon,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          properties: properties,
          url: url,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn create_apage_request(base, data: CreateApageRequest) {
  let method = http.Post
  let path = "/v1/pages"
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #(
          "children",
          json.nullable(data.children, json.array(_, anon_c20d9618_encode)),
        ),
        #("parent", json.nullable(data.parent, anon_f9e4288c_encode)),
        #("properties", json.nullable(data.properties, anon_79ac01f2_encode)),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn create_apage_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use cover <- decode.optional_field(
          "cover",
          None,
          decode.optional(decode.string),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use icon <- decode.optional_field(
          "icon",
          None,
          decode.optional(decode.string),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_fa44d465_decoder()),
        )
        use properties <- decode.optional_field(
          "properties",
          None,
          decode.optional(anon_f8bd2b0a_decoder()),
        )
        use url <- decode.optional_field(
          "url",
          None,
          decode.optional(decode.string),
        )
        decode.success(CreateApageResponse(
          archived: archived,
          cover: cover,
          created_by: created_by,
          created_time: created_time,
          icon: icon,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          properties: properties,
          url: url,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn query_adatabase_request(base, id, data: QueryAdatabaseRequest) {
  let method = http.Post
  let path = "/v1/databases/" <> id <> "/query"
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #("filter", json.nullable(data.filter, anon_f6e3d490_encode)),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn query_adatabase_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use has_more <- decode.optional_field(
          "has_more",
          None,
          decode.optional(decode.bool),
        )
        use next_cursor <- decode.optional_field(
          "next_cursor",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use results <- decode.optional_field(
          "results",
          None,
          decode.optional(decode.list(anon_638ebbba_decoder())),
        )
        decode.success(QueryAdatabaseResponse(
          has_more: has_more,
          next_cursor: next_cursor,
          object: object,
          results: results,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn update_adatabase_request(base, id, data: UpdateAdatabaseRequest) {
  let method = http.Patch
  let path = "/v1/databases/" <> id
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #("properties", json.nullable(data.properties, anon_6175b337_encode)),
        #(
          "title",
          json.nullable(data.title, json.array(_, anon_7a994aba_encode)),
        ),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn update_adatabase_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use cover <- decode.optional_field(
          "cover",
          None,
          decode.optional(decode.string),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use icon <- decode.optional_field(
          "icon",
          None,
          decode.optional(decode.string),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_c5693729_decoder()),
        )
        use properties <- decode.optional_field(
          "properties",
          None,
          decode.optional(anon_bcf7bc9b_decoder()),
        )
        use title <- decode.optional_field(
          "title",
          None,
          decode.optional(decode.list(anon_6547fe66_decoder())),
        )
        use url <- decode.optional_field(
          "url",
          None,
          decode.optional(decode.string),
        )
        decode.success(UpdateAdatabaseResponse(
          archived: archived,
          cover: cover,
          created_by: created_by,
          created_time: created_time,
          icon: icon,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          properties: properties,
          title: title,
          url: url,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_adatabase_request(base, id) {
  let method = http.Get
  let path = "/v1/databases/" <> id
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_adatabase_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use cover <- decode.optional_field(
          "cover",
          None,
          decode.optional(decode.string),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use icon <- decode.optional_field(
          "icon",
          None,
          decode.optional(decode.string),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_c5693729_decoder()),
        )
        use properties <- decode.optional_field(
          "properties",
          None,
          decode.optional(anon_e40599ac_decoder()),
        )
        use title <- decode.optional_field(
          "title",
          None,
          decode.optional(decode.list(anon_6547fe66_decoder())),
        )
        use url <- decode.optional_field(
          "url",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveAdatabaseResponse(
          archived: archived,
          cover: cover,
          created_by: created_by,
          created_time: created_time,
          icon: icon,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          properties: properties,
          title: title,
          url: url,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn create_adatabase_request(base, data: CreateAdatabaseRequest) {
  let method = http.Post
  let path = "/v1/databases"
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #("parent", json.nullable(data.parent, anon_c5693729_encode)),
        #("properties", json.nullable(data.properties, anon_3722994e_encode)),
        #(
          "title",
          json.nullable(data.title, json.array(_, anon_6bec251d_encode)),
        ),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn create_adatabase_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use cover <- decode.optional_field(
          "cover",
          None,
          decode.optional(decode.string),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use icon <- decode.optional_field(
          "icon",
          None,
          decode.optional(decode.string),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_c5693729_decoder()),
        )
        use properties <- decode.optional_field(
          "properties",
          None,
          decode.optional(anon_b6b66157_decoder()),
        )
        use title <- decode.optional_field(
          "title",
          None,
          decode.optional(decode.list(anon_6547fe66_decoder())),
        )
        use url <- decode.optional_field(
          "url",
          None,
          decode.optional(decode.string),
        )
        decode.success(CreateAdatabaseResponse(
          archived: archived,
          cover: cover,
          created_by: created_by,
          created_time: created_time,
          icon: icon,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          properties: properties,
          title: title,
          url: url,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn add_comment_to_page_request(base, data: AddCommentToPageRequest) {
  let method = http.Post
  let path = "/v1/comments"
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #("parent", json.nullable(data.parent, anon_a98b8bc6_encode)),
        #(
          "rich_text",
          json.nullable(data.rich_text, json.array(_, anon_c7f73fca_encode)),
        ),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn add_comment_to_page_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use discussion_id <- decode.optional_field(
          "discussion_id",
          None,
          decode.optional(decode.string),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use parent <- decode.optional_field(
          "parent",
          None,
          decode.optional(anon_0bc52013_decoder()),
        )
        use rich_text <- decode.optional_field(
          "rich_text",
          None,
          decode.optional(decode.list(anon_6547fe66_decoder())),
        )
        decode.success(AddCommentToPageResponse(
          created_by: created_by,
          created_time: created_time,
          discussion_id: discussion_id,
          id: id,
          last_edited_time: last_edited_time,
          object: object,
          parent: parent,
          rich_text: rich_text,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_comments_request(base, block_id block_id, page_size page_size) {
  let method = http.Get
  let path = "/v1/comments"
  let query = [#("block_id", block_id), #("page_size", page_size)]
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_comments_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use comment <- decode.optional_field(
          "comment",
          None,
          decode.optional(
            decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) }),
          ),
        )
        use has_more <- decode.optional_field(
          "has_more",
          None,
          decode.optional(decode.bool),
        )
        use next_cursor <- decode.optional_field(
          "next_cursor",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use results <- decode.optional_field(
          "results",
          None,
          decode.optional(decode.list(anon_2d4a475d_decoder())),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveCommentsResponse(
          comment: comment,
          has_more: has_more,
          next_cursor: next_cursor,
          object: object,
          results: results,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn append_block_children_request(base, id, data: AppendBlockChildrenRequest) {
  let method = http.Patch
  let path = "/v1/blocks/" <> id <> "/children"
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #(
          "children",
          json.nullable(data.children, json.array(_, anon_0413a8c6_encode)),
        ),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn append_block_children_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use child_page <- decode.optional_field(
          "child_page",
          None,
          decode.optional(anon_689d2bb8_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use has_children <- decode.optional_field(
          "has_children",
          None,
          decode.optional(decode.bool),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(AppendBlockChildrenResponse(
          child_page: child_page,
          created_time: created_time,
          has_children: has_children,
          id: id,
          last_edited_time: last_edited_time,
          object: object,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_block_children_request(base, id, page_size page_size) {
  let method = http.Get
  let path = "/v1/blocks/" <> id <> "/children"
  let query = [#("page_size", page_size)]
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_block_children_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use has_more <- decode.optional_field(
          "has_more",
          None,
          decode.optional(decode.bool),
        )
        use next_cursor <- decode.optional_field(
          "next_cursor",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use results <- decode.optional_field(
          "results",
          None,
          decode.optional(decode.list(anon_e3efa372_decoder())),
        )
        decode.success(RetrieveBlockChildrenResponse(
          has_more: has_more,
          next_cursor: next_cursor,
          object: object,
          results: results,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn update_ablock_request(base, id, data: UpdateAblockRequest) {
  let method = http.Patch
  let path = "/v1/blocks/" <> id
  let query = []
  let body =
    utils.json_to_bits(
      utils.object([
        #("paragraph", json.nullable(data.paragraph, anon_f076b6f9_encode)),
      ]),
    )
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
  |> utils.set_body("application/json", body)
}

pub fn update_ablock_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use has_children <- decode.optional_field(
          "has_children",
          None,
          decode.optional(decode.bool),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use paragraph <- decode.optional_field(
          "paragraph",
          None,
          decode.optional(anon_b34b8240_decoder()),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(UpdateAblockResponse(
          created_time: created_time,
          has_children: has_children,
          id: id,
          last_edited_time: last_edited_time,
          object: object,
          paragraph: paragraph,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn delete_ablock_request(base, id) {
  let method = http.Delete
  let path = "/v1/blocks/" <> id
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn delete_ablock_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use archived <- decode.optional_field(
          "archived",
          None,
          decode.optional(decode.bool),
        )
        use created_by <- decode.optional_field(
          "created_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use has_children <- decode.optional_field(
          "has_children",
          None,
          decode.optional(decode.bool),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_by <- decode.optional_field(
          "last_edited_by",
          None,
          decode.optional(anon_c5650f42_decoder()),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use paragraph <- decode.optional_field(
          "paragraph",
          None,
          decode.optional(anon_b34b8240_decoder()),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(DeleteAblockResponse(
          archived: archived,
          created_by: created_by,
          created_time: created_time,
          has_children: has_children,
          id: id,
          last_edited_by: last_edited_by,
          last_edited_time: last_edited_time,
          object: object,
          paragraph: paragraph,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn retrieve_ablock_request(base, id) {
  let method = http.Get
  let path = "/v1/blocks/" <> id
  let query = []
  base
  |> utils.set_method(method)
  |> utils.append_path(path)
  |> utils.set_query(query)
}

pub fn retrieve_ablock_response(response) {
  let response.Response(status:, body:, ..) = response
  case status {
    200 ->
      json.parse_bits(body, {
        use created_time <- decode.optional_field(
          "created_time",
          None,
          decode.optional(decode.string),
        )
        use has_children <- decode.optional_field(
          "has_children",
          None,
          decode.optional(decode.bool),
        )
        use id <- decode.optional_field(
          "id",
          None,
          decode.optional(decode.string),
        )
        use last_edited_time <- decode.optional_field(
          "last_edited_time",
          None,
          decode.optional(decode.string),
        )
        use object <- decode.optional_field(
          "object",
          None,
          decode.optional(decode.string),
        )
        use paragraph <- decode.optional_field(
          "paragraph",
          None,
          decode.optional(anon_b34b8240_decoder()),
        )
        use type_ <- decode.optional_field(
          "type",
          None,
          decode.optional(decode.string),
        )
        decode.success(RetrieveAblockResponse(
          created_time: created_time,
          has_children: has_children,
          id: id,
          last_edited_time: last_edited_time,
          object: object,
          paragraph: paragraph,
          type_: type_,
        ))
      })
      |> result.map(Ok)
    _ -> response |> Error |> Ok
  }
}

pub fn anon_41cfe9c2_decoder() {
  use bold <- decode.optional_field("bold", None, decode.optional(decode.bool))
  use code <- decode.optional_field("code", None, decode.optional(decode.bool))
  use color <- decode.optional_field(
    "color",
    None,
    decode.optional(decode.string),
  )
  use italic <- decode.optional_field(
    "italic",
    None,
    decode.optional(decode.bool),
  )
  use strikethrough <- decode.optional_field(
    "strikethrough",
    None,
    decode.optional(decode.bool),
  )
  use underline <- decode.optional_field(
    "underline",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Anon41cfe9c2(
    bold: bold,
    code: code,
    color: color,
    italic: italic,
    strikethrough: strikethrough,
    underline: underline,
  ))
}

pub fn anon_41cfe9c2_encode(data: Anon41cfe9c2) {
  utils.object([
    #("bold", json.nullable(data.bold, json.bool)),
    #("code", json.nullable(data.code, json.bool)),
    #("color", json.nullable(data.color, json.string)),
    #("italic", json.nullable(data.italic, json.bool)),
    #("strikethrough", json.nullable(data.strikethrough, json.bool)),
    #("underline", json.nullable(data.underline, json.bool)),
  ])
}

pub fn anon_cc655f07_decoder() {
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  decode.success(AnonCc655f07(url: url))
}

pub fn anon_cc655f07_encode(data: AnonCc655f07) {
  utils.object([#("url", json.nullable(data.url, json.string))])
}

pub fn anon_dedd9608_decoder() {
  use content <- decode.optional_field(
    "content",
    None,
    decode.optional(decode.string),
  )
  use link <- decode.optional_field(
    "link",
    None,
    decode.optional(anon_cc655f07_decoder()),
  )
  decode.success(AnonDedd9608(content: content, link: link))
}

pub fn anon_dedd9608_encode(data: AnonDedd9608) {
  utils.object([
    #("content", json.nullable(data.content, json.string)),
    #("link", json.nullable(data.link, anon_cc655f07_encode)),
  ])
}

pub fn anon_6547fe66_decoder() {
  use annotations <- decode.optional_field(
    "annotations",
    None,
    decode.optional(anon_41cfe9c2_decoder()),
  )
  use href <- decode.optional_field(
    "href",
    None,
    decode.optional(decode.string),
  )
  use plain_text <- decode.optional_field(
    "plain_text",
    None,
    decode.optional(decode.string),
  )
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(anon_dedd9608_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon6547fe66(
    annotations: annotations,
    href: href,
    plain_text: plain_text,
    text: text,
    type_: type_,
  ))
}

pub fn anon_6547fe66_encode(data: Anon6547fe66) {
  utils.object([
    #("annotations", json.nullable(data.annotations, anon_41cfe9c2_encode)),
    #("href", json.nullable(data.href, json.string)),
    #("plain_text", json.nullable(data.plain_text, json.string)),
    #("text", json.nullable(data.text, anon_dedd9608_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_b34b8240_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.list(anon_6547fe66_decoder())),
  )
  decode.success(AnonB34b8240(text: text))
}

pub fn anon_b34b8240_encode(data: AnonB34b8240) {
  utils.object([
    #("text", json.nullable(data.text, json.array(_, anon_6547fe66_encode))),
  ])
}

pub fn anon_c5650f42_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonC5650f42(id: id, object: object))
}

pub fn anon_c5650f42_encode(data: AnonC5650f42) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("object", json.nullable(data.object, json.string)),
  ])
}

pub fn anon_d43b5a15_decoder() {
  use content <- decode.optional_field(
    "content",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonD43b5a15(content: content))
}

pub fn anon_d43b5a15_encode(data: AnonD43b5a15) {
  utils.object([#("content", json.nullable(data.content, json.string))])
}

pub fn anon_1b577071_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(anon_d43b5a15_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon1b577071(text: text, type_: type_))
}

pub fn anon_1b577071_encode(data: Anon1b577071) {
  utils.object([
    #("text", json.nullable(data.text, anon_d43b5a15_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_f076b6f9_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.list(anon_1b577071_decoder())),
  )
  decode.success(AnonF076b6f9(text: text))
}

pub fn anon_f076b6f9_encode(data: AnonF076b6f9) {
  utils.object([
    #("text", json.nullable(data.text, json.array(_, anon_1b577071_encode))),
  ])
}

pub fn anon_e3efa372_decoder() {
  use created_time <- decode.optional_field(
    "created_time",
    None,
    decode.optional(decode.string),
  )
  use has_children <- decode.optional_field(
    "has_children",
    None,
    decode.optional(decode.bool),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use last_edited_time <- decode.optional_field(
    "last_edited_time",
    None,
    decode.optional(decode.string),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use paragraph <- decode.optional_field(
    "paragraph",
    None,
    decode.optional(anon_b34b8240_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use unsupported <- decode.optional_field(
    "unsupported",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(AnonE3efa372(
    created_time: created_time,
    has_children: has_children,
    id: id,
    last_edited_time: last_edited_time,
    object: object,
    paragraph: paragraph,
    type_: type_,
    unsupported: unsupported,
  ))
}

pub fn anon_e3efa372_encode(data: AnonE3efa372) {
  utils.object([
    #("created_time", json.nullable(data.created_time, json.string)),
    #("has_children", json.nullable(data.has_children, json.bool)),
    #("id", json.nullable(data.id, json.string)),
    #("last_edited_time", json.nullable(data.last_edited_time, json.string)),
    #("object", json.nullable(data.object, json.string)),
    #("paragraph", json.nullable(data.paragraph, anon_b34b8240_encode)),
    #("type", json.nullable(data.type_, json.string)),
    #(
      "unsupported",
      json.nullable(data.unsupported, fn(_: Nil) { json.null() }),
    ),
  ])
}

pub fn anon_f000d16e_decoder() {
  use content <- decode.optional_field(
    "content",
    None,
    decode.optional(decode.string),
  )
  use link <- decode.optional_field(
    "link",
    None,
    decode.optional(anon_cc655f07_decoder()),
  )
  decode.success(AnonF000d16e(content: content, link: link))
}

pub fn anon_f000d16e_encode(data: AnonF000d16e) {
  utils.object([
    #("content", json.nullable(data.content, json.string)),
    #("link", json.nullable(data.link, anon_cc655f07_encode)),
  ])
}

pub fn anon_96274cab_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(anon_f000d16e_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon96274cab(text: text, type_: type_))
}

pub fn anon_96274cab_encode(data: Anon96274cab) {
  utils.object([
    #("text", json.nullable(data.text, anon_f000d16e_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_15570785_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.list(anon_96274cab_decoder())),
  )
  decode.success(Anon15570785(text: text))
}

pub fn anon_15570785_encode(data: Anon15570785) {
  utils.object([
    #("text", json.nullable(data.text, json.array(_, anon_96274cab_encode))),
  ])
}

pub fn anon_0413a8c6_decoder() {
  use heading_2 <- decode.optional_field(
    "heading_2",
    None,
    decode.optional(anon_f076b6f9_decoder()),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use paragraph <- decode.optional_field(
    "paragraph",
    None,
    decode.optional(anon_15570785_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon0413a8c6(
    heading_2: heading_2,
    object: object,
    paragraph: paragraph,
    type_: type_,
  ))
}

pub fn anon_0413a8c6_encode(data: Anon0413a8c6) {
  utils.object([
    #("heading_2", json.nullable(data.heading_2, anon_f076b6f9_encode)),
    #("object", json.nullable(data.object, json.string)),
    #("paragraph", json.nullable(data.paragraph, anon_15570785_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_689d2bb8_decoder() {
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon689d2bb8(title: title))
}

pub fn anon_689d2bb8_encode(data: Anon689d2bb8) {
  utils.object([#("title", json.nullable(data.title, json.string))])
}

pub fn anon_8882a242_decoder() {
  use block_id <- decode.optional_field(
    "block_id",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon8882a242(block_id: block_id, type_: type_))
}

pub fn anon_8882a242_encode(data: Anon8882a242) {
  utils.object([
    #("block_id", json.nullable(data.block_id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_2d4a475d_decoder() {
  use created_by <- decode.optional_field(
    "created_by",
    None,
    decode.optional(anon_c5650f42_decoder()),
  )
  use created_time <- decode.optional_field(
    "created_time",
    None,
    decode.optional(decode.string),
  )
  use discussion_id <- decode.optional_field(
    "discussion_id",
    None,
    decode.optional(decode.string),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use last_edited_time <- decode.optional_field(
    "last_edited_time",
    None,
    decode.optional(decode.string),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.optional_field(
    "parent",
    None,
    decode.optional(anon_8882a242_decoder()),
  )
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.list(anon_6547fe66_decoder())),
  )
  decode.success(Anon2d4a475d(
    created_by: created_by,
    created_time: created_time,
    discussion_id: discussion_id,
    id: id,
    last_edited_time: last_edited_time,
    object: object,
    parent: parent,
    rich_text: rich_text,
  ))
}

pub fn anon_2d4a475d_encode(data: Anon2d4a475d) {
  utils.object([
    #("created_by", json.nullable(data.created_by, anon_c5650f42_encode)),
    #("created_time", json.nullable(data.created_time, json.string)),
    #("discussion_id", json.nullable(data.discussion_id, json.string)),
    #("id", json.nullable(data.id, json.string)),
    #("last_edited_time", json.nullable(data.last_edited_time, json.string)),
    #("object", json.nullable(data.object, json.string)),
    #("parent", json.nullable(data.parent, anon_8882a242_encode)),
    #(
      "rich_text",
      json.nullable(data.rich_text, json.array(_, anon_6547fe66_encode)),
    ),
  ])
}

pub fn anon_a98b8bc6_decoder() {
  use page_id <- decode.optional_field(
    "page_id",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonA98b8bc6(page_id: page_id))
}

pub fn anon_a98b8bc6_encode(data: AnonA98b8bc6) {
  utils.object([#("page_id", json.nullable(data.page_id, json.string))])
}

pub fn anon_8d557d08_decoder() {
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(anon_c5650f42_decoder()),
  )
  decode.success(Anon8d557d08(user: user))
}

pub fn anon_8d557d08_encode(data: Anon8d557d08) {
  utils.object([#("user", json.nullable(data.user, anon_c5650f42_encode))])
}

pub fn anon_c7f73fca_decoder() {
  use mention <- decode.optional_field(
    "mention",
    None,
    decode.optional(anon_8d557d08_decoder()),
  )
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(anon_d43b5a15_decoder()),
  )
  decode.success(AnonC7f73fca(mention: mention, text: text))
}

pub fn anon_c7f73fca_encode(data: AnonC7f73fca) {
  utils.object([
    #("mention", json.nullable(data.mention, anon_8d557d08_encode)),
    #("text", json.nullable(data.text, anon_d43b5a15_encode)),
  ])
}

pub fn anon_0bc52013_decoder() {
  use block_id <- decode.optional_field(
    "block_id",
    None,
    decode.optional(decode.string),
  )
  use page_id <- decode.optional_field(
    "page_id",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon0bc52013(
    block_id: block_id,
    page_id: page_id,
    type_: type_,
  ))
}

pub fn anon_0bc52013_encode(data: Anon0bc52013) {
  utils.object([
    #("block_id", json.nullable(data.block_id, json.string)),
    #("page_id", json.nullable(data.page_id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_c5693729_decoder() {
  use page_id <- decode.optional_field(
    "page_id",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonC5693729(page_id: page_id, type_: type_))
}

pub fn anon_c5693729_encode(data: AnonC5693729) {
  utils.object([
    #("page_id", json.nullable(data.page_id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_c8c0aec2_decoder() {
  use people <- decode.optional_field(
    "people",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(AnonC8c0aec2(people: people))
}

pub fn anon_c8c0aec2_encode(data: AnonC8c0aec2) {
  utils.object([
    #("people", json.nullable(data.people, fn(_: Nil) { json.null() })),
  ])
}

pub fn anon_1ded2ce6_decoder() {
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(Anon1ded2ce6(rich_text: rich_text))
}

pub fn anon_1ded2ce6_encode(data: Anon1ded2ce6) {
  utils.object([
    #("rich_text", json.nullable(data.rich_text, fn(_: Nil) { json.null() })),
  ])
}

pub fn anon_88cd52c9_decoder() {
  use color <- decode.optional_field(
    "color",
    None,
    decode.optional(decode.string),
  )
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon88cd52c9(color: color, name: name))
}

pub fn anon_88cd52c9_encode(data: Anon88cd52c9) {
  utils.object([
    #("color", json.nullable(data.color, json.string)),
    #("name", json.nullable(data.name, json.string)),
  ])
}

pub fn anon_9dd0af2b_decoder() {
  use options <- decode.optional_field(
    "options",
    None,
    decode.optional(decode.list(anon_88cd52c9_decoder())),
  )
  decode.success(Anon9dd0af2b(options: options))
}

pub fn anon_9dd0af2b_encode(data: Anon9dd0af2b) {
  utils.object([
    #(
      "options",
      json.nullable(data.options, json.array(_, anon_88cd52c9_encode)),
    ),
  ])
}

pub fn anon_4f2ef5d5_decoder() {
  use select <- decode.optional_field(
    "select",
    None,
    decode.optional(anon_9dd0af2b_decoder()),
  )
  decode.success(Anon4f2ef5d5(select: select))
}

pub fn anon_4f2ef5d5_encode(data: Anon4f2ef5d5) {
  utils.object([#("select", json.nullable(data.select, anon_9dd0af2b_encode))])
}

pub fn anon_425d6e5c_decoder() {
  use checkbox <- decode.optional_field(
    "checkbox",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(Anon425d6e5c(checkbox: checkbox))
}

pub fn anon_425d6e5c_encode(data: Anon425d6e5c) {
  utils.object([
    #("checkbox", json.nullable(data.checkbox, fn(_: Nil) { json.null() })),
  ])
}

pub fn anon_1adf7f5d_decoder() {
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(Anon1adf7f5d(date: date))
}

pub fn anon_1adf7f5d_encode(data: Anon1adf7f5d) {
  utils.object([#("date", json.nullable(data.date, fn(_: Nil) { json.null() }))])
}

pub fn anon_c602fa17_decoder() {
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(AnonC602fa17(title: title))
}

pub fn anon_c602fa17_encode(data: AnonC602fa17) {
  utils.object([
    #("title", json.nullable(data.title, fn(_: Nil) { json.null() })),
  ])
}

pub fn anon_7d0bf624_decoder() {
  use files <- decode.optional_field(
    "files",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(Anon7d0bf624(files: files))
}

pub fn anon_7d0bf624_encode(data: Anon7d0bf624) {
  utils.object([
    #("files", json.nullable(data.files, fn(_: Nil) { json.null() })),
  ])
}

pub fn anon_b49d5525_decoder() {
  use format <- decode.optional_field(
    "format",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonB49d5525(format: format))
}

pub fn anon_b49d5525_encode(data: AnonB49d5525) {
  utils.object([#("format", json.nullable(data.format, json.string))])
}

pub fn anon_6d61c900_decoder() {
  use number <- decode.optional_field(
    "number",
    None,
    decode.optional(anon_b49d5525_decoder()),
  )
  decode.success(Anon6d61c900(number: number))
}

pub fn anon_6d61c900_encode(data: Anon6d61c900) {
  utils.object([#("number", json.nullable(data.number, anon_b49d5525_encode))])
}

pub fn anon_357a746a_decoder() {
  use multi_select <- decode.optional_field(
    "multi_select",
    None,
    decode.optional(anon_9dd0af2b_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon357a746a(multi_select: multi_select, type_: type_))
}

pub fn anon_357a746a_encode(data: Anon357a746a) {
  utils.object([
    #("multi_select", json.nullable(data.multi_select, anon_9dd0af2b_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_3722994e_decoder() {
  use positive_1 <- decode.optional_field(
    "+1",
    None,
    decode.optional(anon_c8c0aec2_decoder()),
  )
  use description <- decode.optional_field(
    "Description",
    None,
    decode.optional(anon_1ded2ce6_decoder()),
  )
  use food_group <- decode.optional_field(
    "Food group",
    None,
    decode.optional(anon_4f2ef5d5_decoder()),
  )
  use in_stock <- decode.optional_field(
    "In stock",
    None,
    decode.optional(anon_425d6e5c_decoder()),
  )
  use last_ordered <- decode.optional_field(
    "Last ordered",
    None,
    decode.optional(anon_1adf7f5d_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_c602fa17_decoder()),
  )
  use photo <- decode.optional_field(
    "Photo",
    None,
    decode.optional(anon_7d0bf624_decoder()),
  )
  use price <- decode.optional_field(
    "Price",
    None,
    decode.optional(anon_6d61c900_decoder()),
  )
  use store_availability <- decode.optional_field(
    "Store availability",
    None,
    decode.optional(anon_357a746a_decoder()),
  )
  decode.success(Anon3722994e(
    positive_1: positive_1,
    description: description,
    food_group: food_group,
    in_stock: in_stock,
    last_ordered: last_ordered,
    name: name,
    photo: photo,
    price: price,
    store_availability: store_availability,
  ))
}

pub fn anon_3722994e_encode(data: Anon3722994e) {
  utils.object([
    #("+1", json.nullable(data.positive_1, anon_c8c0aec2_encode)),
    #("Description", json.nullable(data.description, anon_1ded2ce6_encode)),
    #("Food group", json.nullable(data.food_group, anon_4f2ef5d5_encode)),
    #("In stock", json.nullable(data.in_stock, anon_425d6e5c_encode)),
    #("Last ordered", json.nullable(data.last_ordered, anon_1adf7f5d_encode)),
    #("Name", json.nullable(data.name, anon_c602fa17_encode)),
    #("Photo", json.nullable(data.photo, anon_7d0bf624_encode)),
    #("Price", json.nullable(data.price, anon_6d61c900_encode)),
    #(
      "Store availability",
      json.nullable(data.store_availability, anon_357a746a_encode),
    ),
  ])
}

pub fn anon_6bec251d_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(anon_dedd9608_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon6bec251d(text: text, type_: type_))
}

pub fn anon_6bec251d_encode(data: Anon6bec251d) {
  utils.object([
    #("text", json.nullable(data.text, anon_dedd9608_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_419560a7_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use people <- decode.optional_field(
    "people",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon419560a7(id: id, name: name, people: people, type_: type_))
}

pub fn anon_419560a7_encode(data: Anon419560a7) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("people", json.nullable(data.people, fn(_: Nil) { json.null() })),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_5ed12ef0_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon5ed12ef0(
    id: id,
    name: name,
    rich_text: rich_text,
    type_: type_,
  ))
}

pub fn anon_5ed12ef0_encode(data: Anon5ed12ef0) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("rich_text", json.nullable(data.rich_text, fn(_: Nil) { json.null() })),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_1a5d0865_decoder() {
  use color <- decode.optional_field(
    "color",
    None,
    decode.optional(decode.string),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon1a5d0865(color: color, id: id, name: name))
}

pub fn anon_1a5d0865_encode(data: Anon1a5d0865) {
  utils.object([
    #("color", json.nullable(data.color, json.string)),
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
  ])
}

pub fn anon_1ac3a1b3_decoder() {
  use options <- decode.optional_field(
    "options",
    None,
    decode.optional(decode.list(anon_1a5d0865_decoder())),
  )
  decode.success(Anon1ac3a1b3(options: options))
}

pub fn anon_1ac3a1b3_encode(data: Anon1ac3a1b3) {
  utils.object([
    #(
      "options",
      json.nullable(data.options, json.array(_, anon_1a5d0865_encode)),
    ),
  ])
}

pub fn anon_97e8db5f_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use select <- decode.optional_field(
    "select",
    None,
    decode.optional(anon_1ac3a1b3_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon97e8db5f(id: id, name: name, select: select, type_: type_))
}

pub fn anon_97e8db5f_encode(data: Anon97e8db5f) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("select", json.nullable(data.select, anon_1ac3a1b3_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_33d8fac3_decoder() {
  use checkbox <- decode.optional_field(
    "checkbox",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon33d8fac3(
    checkbox: checkbox,
    id: id,
    name: name,
    type_: type_,
  ))
}

pub fn anon_33d8fac3_encode(data: Anon33d8fac3) {
  utils.object([
    #("checkbox", json.nullable(data.checkbox, fn(_: Nil) { json.null() })),
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_63b0ebf8_decoder() {
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon63b0ebf8(date: date, id: id, name: name, type_: type_))
}

pub fn anon_63b0ebf8_encode(data: Anon63b0ebf8) {
  utils.object([
    #("date", json.nullable(data.date, fn(_: Nil) { json.null() })),
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_cf985fdc_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonCf985fdc(id: id, name: name, title: title, type_: type_))
}

pub fn anon_cf985fdc_encode(data: AnonCf985fdc) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("title", json.nullable(data.title, fn(_: Nil) { json.null() })),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_bd3eeb6e_decoder() {
  use files <- decode.optional_field(
    "files",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonBd3eeb6e(files: files, id: id, name: name, type_: type_))
}

pub fn anon_bd3eeb6e_encode(data: AnonBd3eeb6e) {
  utils.object([
    #("files", json.nullable(data.files, fn(_: Nil) { json.null() })),
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_ca26f6a6_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use number <- decode.optional_field(
    "number",
    None,
    decode.optional(anon_b49d5525_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonCa26f6a6(id: id, name: name, number: number, type_: type_))
}

pub fn anon_ca26f6a6_encode(data: AnonCa26f6a6) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("number", json.nullable(data.number, anon_b49d5525_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_283ff0af_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use multi_select <- decode.optional_field(
    "multi_select",
    None,
    decode.optional(anon_1ac3a1b3_decoder()),
  )
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon283ff0af(
    id: id,
    multi_select: multi_select,
    name: name,
    type_: type_,
  ))
}

pub fn anon_283ff0af_encode(data: Anon283ff0af) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("multi_select", json.nullable(data.multi_select, anon_1ac3a1b3_encode)),
    #("name", json.nullable(data.name, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_b6b66157_decoder() {
  use positive_1 <- decode.optional_field(
    "+1",
    None,
    decode.optional(anon_419560a7_decoder()),
  )
  use description <- decode.optional_field(
    "Description",
    None,
    decode.optional(anon_5ed12ef0_decoder()),
  )
  use food_group <- decode.optional_field(
    "Food group",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use in_stock <- decode.optional_field(
    "In stock",
    None,
    decode.optional(anon_33d8fac3_decoder()),
  )
  use last_ordered <- decode.optional_field(
    "Last ordered",
    None,
    decode.optional(anon_63b0ebf8_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_cf985fdc_decoder()),
  )
  use photo <- decode.optional_field(
    "Photo",
    None,
    decode.optional(anon_bd3eeb6e_decoder()),
  )
  use price <- decode.optional_field(
    "Price",
    None,
    decode.optional(anon_ca26f6a6_decoder()),
  )
  use store_availability <- decode.optional_field(
    "Store availability",
    None,
    decode.optional(anon_283ff0af_decoder()),
  )
  decode.success(AnonB6b66157(
    positive_1: positive_1,
    description: description,
    food_group: food_group,
    in_stock: in_stock,
    last_ordered: last_ordered,
    name: name,
    photo: photo,
    price: price,
    store_availability: store_availability,
  ))
}

pub fn anon_b6b66157_encode(data: AnonB6b66157) {
  utils.object([
    #("+1", json.nullable(data.positive_1, anon_419560a7_encode)),
    #("Description", json.nullable(data.description, anon_5ed12ef0_encode)),
    #("Food group", json.nullable(data.food_group, anon_97e8db5f_encode)),
    #("In stock", json.nullable(data.in_stock, anon_33d8fac3_encode)),
    #("Last ordered", json.nullable(data.last_ordered, anon_63b0ebf8_encode)),
    #("Name", json.nullable(data.name, anon_cf985fdc_encode)),
    #("Photo", json.nullable(data.photo, anon_bd3eeb6e_encode)),
    #("Price", json.nullable(data.price, anon_ca26f6a6_encode)),
    #(
      "Store availability",
      json.nullable(data.store_availability, anon_283ff0af_encode),
    ),
  ])
}

pub fn anon_484ec035_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use url <- decode.optional_field(
    "url",
    None,
    decode.optional(decode.new_primitive_decoder("Nil", fn(_) { Ok(Nil) })),
  )
  decode.success(Anon484ec035(id: id, name: name, type_: type_, url: url))
}

pub fn anon_484ec035_encode(data: Anon484ec035) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("type", json.nullable(data.type_, json.string)),
    #("url", json.nullable(data.url, fn(_: Nil) { json.null() })),
  ])
}

pub fn anon_e40599ac_decoder() {
  use author <- decode.optional_field(
    "Author",
    None,
    decode.optional(anon_283ff0af_decoder()),
  )
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_484ec035_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_cf985fdc_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_63b0ebf8_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_33d8fac3_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_5ed12ef0_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  decode.success(AnonE40599ac(
    author: author,
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
  ))
}

pub fn anon_e40599ac_encode(data: AnonE40599ac) {
  utils.object([
    #("Author", json.nullable(data.author, anon_283ff0af_encode)),
    #("Link", json.nullable(data.link, anon_484ec035_encode)),
    #("Name", json.nullable(data.name, anon_cf985fdc_encode)),
    #("Publisher", json.nullable(data.publisher, anon_97e8db5f_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_63b0ebf8_encode),
    ),
    #("Read", json.nullable(data.read, anon_33d8fac3_encode)),
    #("Score /5", json.nullable(data.score__5, anon_97e8db5f_encode)),
    #("Status", json.nullable(data.status, anon_97e8db5f_encode)),
    #("Summary", json.nullable(data.summary, anon_5ed12ef0_encode)),
    #("Type", json.nullable(data.type_, anon_97e8db5f_encode)),
  ])
}

pub fn anon_6175b337_decoder() {
  use wine_pairing <- decode.optional_field(
    "Wine Pairing",
    None,
    decode.optional(anon_1ded2ce6_decoder()),
  )
  decode.success(Anon6175b337(wine_pairing: wine_pairing))
}

pub fn anon_6175b337_encode(data: Anon6175b337) {
  utils.object([
    #("Wine Pairing", json.nullable(data.wine_pairing, anon_1ded2ce6_encode)),
  ])
}

pub fn anon_7a994aba_decoder() {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(anon_d43b5a15_decoder()),
  )
  decode.success(Anon7a994aba(text: text))
}

pub fn anon_7a994aba_encode(data: Anon7a994aba) {
  utils.object([#("text", json.nullable(data.text, anon_d43b5a15_encode))])
}

pub fn anon_bcf7bc9b_decoder() {
  use author <- decode.optional_field(
    "Author",
    None,
    decode.optional(anon_283ff0af_decoder()),
  )
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_484ec035_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_cf985fdc_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_63b0ebf8_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_33d8fac3_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_5ed12ef0_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_97e8db5f_decoder()),
  )
  use wine_pairing <- decode.optional_field(
    "Wine Pairing",
    None,
    decode.optional(anon_5ed12ef0_decoder()),
  )
  decode.success(AnonBcf7bc9b(
    author: author,
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
    wine_pairing: wine_pairing,
  ))
}

pub fn anon_bcf7bc9b_encode(data: AnonBcf7bc9b) {
  utils.object([
    #("Author", json.nullable(data.author, anon_283ff0af_encode)),
    #("Link", json.nullable(data.link, anon_484ec035_encode)),
    #("Name", json.nullable(data.name, anon_cf985fdc_encode)),
    #("Publisher", json.nullable(data.publisher, anon_97e8db5f_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_63b0ebf8_encode),
    ),
    #("Read", json.nullable(data.read, anon_33d8fac3_encode)),
    #("Score /5", json.nullable(data.score__5, anon_97e8db5f_encode)),
    #("Status", json.nullable(data.status, anon_97e8db5f_encode)),
    #("Summary", json.nullable(data.summary, anon_5ed12ef0_encode)),
    #("Type", json.nullable(data.type_, anon_97e8db5f_encode)),
    #("Wine Pairing", json.nullable(data.wine_pairing, anon_5ed12ef0_encode)),
  ])
}

pub fn anon_2795bf82_decoder() {
  use equals <- decode.optional_field(
    "equals",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon2795bf82(equals: equals))
}

pub fn anon_2795bf82_encode(data: Anon2795bf82) {
  utils.object([#("equals", json.nullable(data.equals, json.string))])
}

pub fn anon_f6e3d490_decoder() {
  use property <- decode.optional_field(
    "property",
    None,
    decode.optional(decode.string),
  )
  use select <- decode.optional_field(
    "select",
    None,
    decode.optional(anon_2795bf82_decoder()),
  )
  decode.success(AnonF6e3d490(property: property, select: select))
}

pub fn anon_f6e3d490_encode(data: AnonF6e3d490) {
  utils.object([
    #("property", json.nullable(data.property, json.string)),
    #("select", json.nullable(data.select, anon_2795bf82_encode)),
  ])
}

pub fn anon_fa44d465_decoder() {
  use database_id <- decode.optional_field(
    "database_id",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonFa44d465(database_id: database_id, type_: type_))
}

pub fn anon_fa44d465_encode(data: AnonFa44d465) {
  utils.object([
    #("database_id", json.nullable(data.database_id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_161e1529_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use multi_select <- decode.optional_field(
    "multi_select",
    None,
    decode.optional(decode.list(anon_1a5d0865_decoder())),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon161e1529(id: id, multi_select: multi_select, type_: type_))
}

pub fn anon_161e1529_encode(data: Anon161e1529) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #(
      "multi_select",
      json.nullable(data.multi_select, json.array(_, anon_1a5d0865_encode)),
    ),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_8843700c_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  decode.success(Anon8843700c(id: id, type_: type_, url: url))
}

pub fn anon_8843700c_encode(data: Anon8843700c) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
    #("url", json.nullable(data.url, json.string)),
  ])
}

pub fn anon_aa5ae26f_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.list(anon_6547fe66_decoder())),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonAa5ae26f(id: id, title: title, type_: type_))
}

pub fn anon_aa5ae26f_encode(data: AnonAa5ae26f) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("title", json.nullable(data.title, json.array(_, anon_6547fe66_encode))),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_bfe18c29_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use select <- decode.optional_field(
    "select",
    None,
    decode.optional(anon_1a5d0865_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonBfe18c29(id: id, select: select, type_: type_))
}

pub fn anon_bfe18c29_encode(data: AnonBfe18c29) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("select", json.nullable(data.select, anon_1a5d0865_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_7dffc985_decoder() {
  use end <- decode.optional_field("end", None, decode.optional(decode.string))
  use start <- decode.optional_field(
    "start",
    None,
    decode.optional(decode.string),
  )
  use time_zone <- decode.optional_field(
    "time_zone",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon7dffc985(end: end, start: start, time_zone: time_zone))
}

pub fn anon_7dffc985_encode(data: Anon7dffc985) {
  utils.object([
    #("end", json.nullable(data.end, json.string)),
    #("start", json.nullable(data.start, json.string)),
    #("time_zone", json.nullable(data.time_zone, json.string)),
  ])
}

pub fn anon_78adfe19_decoder() {
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(anon_7dffc985_decoder()),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon78adfe19(date: date, id: id, type_: type_))
}

pub fn anon_78adfe19_encode(data: Anon78adfe19) {
  utils.object([
    #("date", json.nullable(data.date, anon_7dffc985_encode)),
    #("id", json.nullable(data.id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_cd3ace58_decoder() {
  use checkbox <- decode.optional_field(
    "checkbox",
    None,
    decode.optional(decode.bool),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonCd3ace58(checkbox: checkbox, id: id, type_: type_))
}

pub fn anon_cd3ace58_encode(data: AnonCd3ace58) {
  utils.object([
    #("checkbox", json.nullable(data.checkbox, json.bool)),
    #("id", json.nullable(data.id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_30481f82_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use select <- decode.optional_field(
    "select",
    None,
    decode.optional(anon_1a5d0865_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon30481f82(id: id, select: select, type_: type_))
}

pub fn anon_30481f82_encode(data: Anon30481f82) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #("select", json.nullable(data.select, anon_1a5d0865_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_6af8e0a7_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.list(anon_6547fe66_decoder())),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon6af8e0a7(id: id, rich_text: rich_text, type_: type_))
}

pub fn anon_6af8e0a7_encode(data: Anon6af8e0a7) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #(
      "rich_text",
      json.nullable(data.rich_text, json.array(_, anon_6547fe66_encode)),
    ),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_858342ba_decoder() {
  use author <- decode.optional_field(
    "Author",
    None,
    decode.optional(anon_161e1529_decoder()),
  )
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_8843700c_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_aa5ae26f_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_78adfe19_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_cd3ace58_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_30481f82_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_6af8e0a7_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  decode.success(Anon858342ba(
    author: author,
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
  ))
}

pub fn anon_858342ba_encode(data: Anon858342ba) {
  utils.object([
    #("Author", json.nullable(data.author, anon_161e1529_encode)),
    #("Link", json.nullable(data.link, anon_8843700c_encode)),
    #("Name", json.nullable(data.name, anon_aa5ae26f_encode)),
    #("Publisher", json.nullable(data.publisher, anon_bfe18c29_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_78adfe19_encode),
    ),
    #("Read", json.nullable(data.read, anon_cd3ace58_encode)),
    #("Score /5", json.nullable(data.score__5, anon_30481f82_encode)),
    #("Status", json.nullable(data.status, anon_bfe18c29_encode)),
    #("Summary", json.nullable(data.summary, anon_6af8e0a7_encode)),
    #("Type", json.nullable(data.type_, anon_bfe18c29_encode)),
  ])
}

pub fn anon_638ebbba_decoder() {
  use archived <- decode.optional_field(
    "archived",
    None,
    decode.optional(decode.bool),
  )
  use cover <- decode.optional_field(
    "cover",
    None,
    decode.optional(decode.string),
  )
  use created_by <- decode.optional_field(
    "created_by",
    None,
    decode.optional(anon_c5650f42_decoder()),
  )
  use created_time <- decode.optional_field(
    "created_time",
    None,
    decode.optional(decode.string),
  )
  use icon <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use last_edited_by <- decode.optional_field(
    "last_edited_by",
    None,
    decode.optional(anon_c5650f42_decoder()),
  )
  use last_edited_time <- decode.optional_field(
    "last_edited_time",
    None,
    decode.optional(decode.string),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.optional_field(
    "parent",
    None,
    decode.optional(anon_fa44d465_decoder()),
  )
  use properties <- decode.optional_field(
    "properties",
    None,
    decode.optional(anon_858342ba_decoder()),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  decode.success(Anon638ebbba(
    archived: archived,
    cover: cover,
    created_by: created_by,
    created_time: created_time,
    icon: icon,
    id: id,
    last_edited_by: last_edited_by,
    last_edited_time: last_edited_time,
    object: object,
    parent: parent,
    properties: properties,
    url: url,
  ))
}

pub fn anon_638ebbba_encode(data: Anon638ebbba) {
  utils.object([
    #("archived", json.nullable(data.archived, json.bool)),
    #("cover", json.nullable(data.cover, json.string)),
    #("created_by", json.nullable(data.created_by, anon_c5650f42_encode)),
    #("created_time", json.nullable(data.created_time, json.string)),
    #("icon", json.nullable(data.icon, json.string)),
    #("id", json.nullable(data.id, json.string)),
    #(
      "last_edited_by",
      json.nullable(data.last_edited_by, anon_c5650f42_encode),
    ),
    #("last_edited_time", json.nullable(data.last_edited_time, json.string)),
    #("object", json.nullable(data.object, json.string)),
    #("parent", json.nullable(data.parent, anon_fa44d465_encode)),
    #("properties", json.nullable(data.properties, anon_858342ba_encode)),
    #("url", json.nullable(data.url, json.string)),
  ])
}

pub fn anon_ade1189e_decoder() {
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.list(anon_1b577071_decoder())),
  )
  decode.success(AnonAde1189e(rich_text: rich_text))
}

pub fn anon_ade1189e_encode(data: AnonAde1189e) {
  utils.object([
    #(
      "rich_text",
      json.nullable(data.rich_text, json.array(_, anon_1b577071_encode)),
    ),
  ])
}

pub fn anon_c20d9618_decoder() {
  use heading_2 <- decode.optional_field(
    "heading_2",
    None,
    decode.optional(anon_ade1189e_decoder()),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use paragraph <- decode.optional_field(
    "paragraph",
    None,
    decode.optional(anon_15570785_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonC20d9618(
    heading_2: heading_2,
    object: object,
    paragraph: paragraph,
    type_: type_,
  ))
}

pub fn anon_c20d9618_encode(data: AnonC20d9618) {
  utils.object([
    #("heading_2", json.nullable(data.heading_2, anon_ade1189e_encode)),
    #("object", json.nullable(data.object, json.string)),
    #("paragraph", json.nullable(data.paragraph, anon_15570785_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_f9e4288c_decoder() {
  use database_id <- decode.optional_field(
    "database_id",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonF9e4288c(database_id: database_id))
}

pub fn anon_f9e4288c_encode(data: AnonF9e4288c) {
  utils.object([#("database_id", json.nullable(data.database_id, json.string))])
}

pub fn anon_6e9b6d9d_decoder() {
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.list(anon_7a994aba_decoder())),
  )
  decode.success(Anon6e9b6d9d(title: title))
}

pub fn anon_6e9b6d9d_encode(data: Anon6e9b6d9d) {
  utils.object([
    #("title", json.nullable(data.title, json.array(_, anon_7a994aba_encode))),
  ])
}

pub fn anon_2bd864ec_decoder() {
  use select <- decode.optional_field(
    "select",
    None,
    decode.optional(anon_1a5d0865_decoder()),
  )
  decode.success(Anon2bd864ec(select: select))
}

pub fn anon_2bd864ec_encode(data: Anon2bd864ec) {
  utils.object([#("select", json.nullable(data.select, anon_1a5d0865_encode))])
}

pub fn anon_750d4b8a_decoder() {
  use end <- decode.optional_field("end", None, decode.optional(decode.string))
  use start <- decode.optional_field(
    "start",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon750d4b8a(end: end, start: start))
}

pub fn anon_750d4b8a_encode(data: Anon750d4b8a) {
  utils.object([
    #("end", json.nullable(data.end, json.string)),
    #("start", json.nullable(data.start, json.string)),
  ])
}

pub fn anon_43b73855_decoder() {
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(anon_750d4b8a_decoder()),
  )
  decode.success(Anon43b73855(date: date))
}

pub fn anon_43b73855_encode(data: Anon43b73855) {
  utils.object([#("date", json.nullable(data.date, anon_750d4b8a_encode))])
}

pub fn anon_22c04b67_decoder() {
  use checkbox <- decode.optional_field(
    "checkbox",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Anon22c04b67(checkbox: checkbox))
}

pub fn anon_22c04b67_encode(data: Anon22c04b67) {
  utils.object([#("checkbox", json.nullable(data.checkbox, json.bool))])
}

pub fn anon_e374b215_decoder() {
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.list(anon_6547fe66_decoder())),
  )
  decode.success(AnonE374b215(rich_text: rich_text))
}

pub fn anon_e374b215_encode(data: AnonE374b215) {
  utils.object([
    #(
      "rich_text",
      json.nullable(data.rich_text, json.array(_, anon_6547fe66_encode)),
    ),
  ])
}

pub fn anon_79ac01f2_decoder() {
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_cc655f07_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_6e9b6d9d_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_2bd864ec_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_43b73855_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_22c04b67_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_2bd864ec_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_2bd864ec_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_e374b215_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_2bd864ec_decoder()),
  )
  decode.success(Anon79ac01f2(
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
  ))
}

pub fn anon_79ac01f2_encode(data: Anon79ac01f2) {
  utils.object([
    #("Link", json.nullable(data.link, anon_cc655f07_encode)),
    #("Name", json.nullable(data.name, anon_6e9b6d9d_encode)),
    #("Publisher", json.nullable(data.publisher, anon_2bd864ec_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_43b73855_encode),
    ),
    #("Read", json.nullable(data.read, anon_22c04b67_encode)),
    #("Score /5", json.nullable(data.score__5, anon_2bd864ec_encode)),
    #("Status", json.nullable(data.status, anon_2bd864ec_encode)),
    #("Summary", json.nullable(data.summary, anon_e374b215_encode)),
    #("Type", json.nullable(data.type_, anon_2bd864ec_encode)),
  ])
}

pub fn anon_53c57fa2_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use multi_select <- decode.optional_field(
    "multi_select",
    None,
    decode.optional(decode.list(utils.any_decoder())),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon53c57fa2(id: id, multi_select: multi_select, type_: type_))
}

pub fn anon_53c57fa2_encode(data: Anon53c57fa2) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #(
      "multi_select",
      json.nullable(data.multi_select, json.array(_, utils.any_to_json)),
    ),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_f8bd2b0a_decoder() {
  use author <- decode.optional_field(
    "Author",
    None,
    decode.optional(anon_53c57fa2_decoder()),
  )
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_8843700c_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_aa5ae26f_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_78adfe19_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_cd3ace58_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_6af8e0a7_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  decode.success(AnonF8bd2b0a(
    author: author,
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
  ))
}

pub fn anon_f8bd2b0a_encode(data: AnonF8bd2b0a) {
  utils.object([
    #("Author", json.nullable(data.author, anon_53c57fa2_encode)),
    #("Link", json.nullable(data.link, anon_8843700c_encode)),
    #("Name", json.nullable(data.name, anon_aa5ae26f_encode)),
    #("Publisher", json.nullable(data.publisher, anon_bfe18c29_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_78adfe19_encode),
    ),
    #("Read", json.nullable(data.read, anon_cd3ace58_encode)),
    #("Score /5", json.nullable(data.score__5, anon_bfe18c29_encode)),
    #("Status", json.nullable(data.status, anon_bfe18c29_encode)),
    #("Summary", json.nullable(data.summary, anon_6af8e0a7_encode)),
    #("Type", json.nullable(data.type_, anon_bfe18c29_encode)),
  ])
}

pub fn anon_38aba9ed_decoder() {
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon38aba9ed(emoji: emoji, type_: type_))
}

pub fn anon_38aba9ed_encode(data: Anon38aba9ed) {
  utils.object([
    #("emoji", json.nullable(data.emoji, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_9e677ad4_decoder() {
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(anon_aa5ae26f_decoder()),
  )
  decode.success(Anon9e677ad4(title: title))
}

pub fn anon_9e677ad4_encode(data: Anon9e677ad4) {
  utils.object([#("title", json.nullable(data.title, anon_aa5ae26f_encode))])
}

pub fn anon_d9627bc6_decoder() {
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(anon_750d4b8a_decoder()),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(AnonD9627bc6(date: date, id: id, type_: type_))
}

pub fn anon_d9627bc6_encode(data: AnonD9627bc6) {
  utils.object([
    #("date", json.nullable(data.date, anon_750d4b8a_encode)),
    #("id", json.nullable(data.id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_56b0c7e7_decoder() {
  use author <- decode.optional_field(
    "Author",
    None,
    decode.optional(anon_161e1529_decoder()),
  )
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_8843700c_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_aa5ae26f_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_d9627bc6_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_cd3ace58_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_6af8e0a7_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  decode.success(Anon56b0c7e7(
    author: author,
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
  ))
}

pub fn anon_56b0c7e7_encode(data: Anon56b0c7e7) {
  utils.object([
    #("Author", json.nullable(data.author, anon_161e1529_encode)),
    #("Link", json.nullable(data.link, anon_8843700c_encode)),
    #("Name", json.nullable(data.name, anon_aa5ae26f_encode)),
    #("Publisher", json.nullable(data.publisher, anon_bfe18c29_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_d9627bc6_encode),
    ),
    #("Read", json.nullable(data.read, anon_cd3ace58_encode)),
    #("Score /5", json.nullable(data.score__5, anon_bfe18c29_encode)),
    #("Status", json.nullable(data.status, anon_bfe18c29_encode)),
    #("Summary", json.nullable(data.summary, anon_6af8e0a7_encode)),
    #("Type", json.nullable(data.type_, anon_bfe18c29_encode)),
  ])
}

pub fn anon_01bf2ac9_decoder() {
  use direction <- decode.optional_field(
    "direction",
    None,
    decode.optional(decode.string),
  )
  use timestamp <- decode.optional_field(
    "timestamp",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon01bf2ac9(direction: direction, timestamp: timestamp))
}

pub fn anon_01bf2ac9_encode(data: Anon01bf2ac9) {
  utils.object([
    #("direction", json.nullable(data.direction, json.string)),
    #("timestamp", json.nullable(data.timestamp, json.string)),
  ])
}

pub fn anon_4d415cb6_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use rich_text <- decode.optional_field(
    "rich_text",
    None,
    decode.optional(decode.list(utils.any_decoder())),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon4d415cb6(id: id, rich_text: rich_text, type_: type_))
}

pub fn anon_4d415cb6_encode(data: Anon4d415cb6) {
  utils.object([
    #("id", json.nullable(data.id, json.string)),
    #(
      "rich_text",
      json.nullable(data.rich_text, json.array(_, utils.any_to_json)),
    ),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_378ba014_decoder() {
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(decode.string),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon378ba014(date: date, id: id, type_: type_))
}

pub fn anon_378ba014_encode(data: Anon378ba014) {
  utils.object([
    #("date", json.nullable(data.date, json.string)),
    #("id", json.nullable(data.id, json.string)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}

pub fn anon_9e0f6f2e_decoder() {
  use author <- decode.optional_field(
    "Author",
    None,
    decode.optional(anon_53c57fa2_decoder()),
  )
  use link <- decode.optional_field(
    "Link",
    None,
    decode.optional(anon_8843700c_decoder()),
  )
  use name <- decode.optional_field(
    "Name",
    None,
    decode.optional(anon_aa5ae26f_decoder()),
  )
  use publisher <- decode.optional_field(
    "Publisher",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use publishing__release_date <- decode.optional_field(
    "Publishing/Release Date",
    None,
    decode.optional(anon_78adfe19_decoder()),
  )
  use read <- decode.optional_field(
    "Read",
    None,
    decode.optional(anon_cd3ace58_decoder()),
  )
  use score__5 <- decode.optional_field(
    "Score /5",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use status <- decode.optional_field(
    "Status",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use summary <- decode.optional_field(
    "Summary",
    None,
    decode.optional(anon_6af8e0a7_decoder()),
  )
  use type_ <- decode.optional_field(
    "Type",
    None,
    decode.optional(anon_bfe18c29_decoder()),
  )
  use wine_pairing <- decode.optional_field(
    "Wine Pairing",
    None,
    decode.optional(anon_4d415cb6_decoder()),
  )
  use date <- decode.optional_field(
    "date",
    None,
    decode.optional(anon_378ba014_decoder()),
  )
  decode.success(Anon9e0f6f2e(
    author: author,
    link: link,
    name: name,
    publisher: publisher,
    publishing__release_date: publishing__release_date,
    read: read,
    score__5: score__5,
    status: status,
    summary: summary,
    type_: type_,
    wine_pairing: wine_pairing,
    date: date,
  ))
}

pub fn anon_9e0f6f2e_encode(data: Anon9e0f6f2e) {
  utils.object([
    #("Author", json.nullable(data.author, anon_53c57fa2_encode)),
    #("Link", json.nullable(data.link, anon_8843700c_encode)),
    #("Name", json.nullable(data.name, anon_aa5ae26f_encode)),
    #("Publisher", json.nullable(data.publisher, anon_bfe18c29_encode)),
    #(
      "Publishing/Release Date",
      json.nullable(data.publishing__release_date, anon_78adfe19_encode),
    ),
    #("Read", json.nullable(data.read, anon_cd3ace58_encode)),
    #("Score /5", json.nullable(data.score__5, anon_bfe18c29_encode)),
    #("Status", json.nullable(data.status, anon_bfe18c29_encode)),
    #("Summary", json.nullable(data.summary, anon_6af8e0a7_encode)),
    #("Type", json.nullable(data.type_, anon_bfe18c29_encode)),
    #("Wine Pairing", json.nullable(data.wine_pairing, anon_4d415cb6_encode)),
    #("date", json.nullable(data.date, anon_378ba014_encode)),
  ])
}

pub fn anon_f122065e_decoder() {
  use archived <- decode.optional_field(
    "archived",
    None,
    decode.optional(decode.bool),
  )
  use cover <- decode.optional_field(
    "cover",
    None,
    decode.optional(decode.string),
  )
  use created_by <- decode.optional_field(
    "created_by",
    None,
    decode.optional(anon_c5650f42_decoder()),
  )
  use created_time <- decode.optional_field(
    "created_time",
    None,
    decode.optional(decode.string),
  )
  use icon <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use last_edited_by <- decode.optional_field(
    "last_edited_by",
    None,
    decode.optional(anon_c5650f42_decoder()),
  )
  use last_edited_time <- decode.optional_field(
    "last_edited_time",
    None,
    decode.optional(decode.string),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.optional_field(
    "parent",
    None,
    decode.optional(anon_fa44d465_decoder()),
  )
  use properties <- decode.optional_field(
    "properties",
    None,
    decode.optional(anon_9e0f6f2e_decoder()),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  decode.success(AnonF122065e(
    archived: archived,
    cover: cover,
    created_by: created_by,
    created_time: created_time,
    icon: icon,
    id: id,
    last_edited_by: last_edited_by,
    last_edited_time: last_edited_time,
    object: object,
    parent: parent,
    properties: properties,
    url: url,
  ))
}

pub fn anon_f122065e_encode(data: AnonF122065e) {
  utils.object([
    #("archived", json.nullable(data.archived, json.bool)),
    #("cover", json.nullable(data.cover, json.string)),
    #("created_by", json.nullable(data.created_by, anon_c5650f42_encode)),
    #("created_time", json.nullable(data.created_time, json.string)),
    #("icon", json.nullable(data.icon, json.string)),
    #("id", json.nullable(data.id, json.string)),
    #(
      "last_edited_by",
      json.nullable(data.last_edited_by, anon_c5650f42_encode),
    ),
    #("last_edited_time", json.nullable(data.last_edited_time, json.string)),
    #("object", json.nullable(data.object, json.string)),
    #("parent", json.nullable(data.parent, anon_fa44d465_encode)),
    #("properties", json.nullable(data.properties, anon_9e0f6f2e_encode)),
    #("url", json.nullable(data.url, json.string)),
  ])
}

pub fn anon_2df27035_decoder() {
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use workspace <- decode.optional_field(
    "workspace",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Anon2df27035(type_: type_, workspace: workspace))
}

pub fn anon_2df27035_encode(data: Anon2df27035) {
  utils.object([
    #("type", json.nullable(data.type_, json.string)),
    #("workspace", json.nullable(data.workspace, json.bool)),
  ])
}

pub fn anon_fec5f02c_decoder() {
  use owner <- decode.optional_field(
    "owner",
    None,
    decode.optional(anon_2df27035_decoder()),
  )
  decode.success(AnonFec5f02c(owner: owner))
}

pub fn anon_fec5f02c_encode(data: AnonFec5f02c) {
  utils.object([#("owner", json.nullable(data.owner, anon_2df27035_encode))])
}

pub fn anon_8818ae5d_decoder() {
  use email <- decode.optional_field(
    "email",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon8818ae5d(email: email))
}

pub fn anon_8818ae5d_encode(data: Anon8818ae5d) {
  utils.object([#("email", json.nullable(data.email, json.string))])
}

pub fn anon_84b72b7f_decoder() {
  use avatar_url <- decode.optional_field(
    "avatar_url",
    None,
    decode.optional(decode.string),
  )
  use bot <- decode.optional_field(
    "bot",
    None,
    decode.optional(anon_fec5f02c_decoder()),
  )
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use object <- decode.optional_field(
    "object",
    None,
    decode.optional(decode.string),
  )
  use person <- decode.optional_field(
    "person",
    None,
    decode.optional(anon_8818ae5d_decoder()),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(Anon84b72b7f(
    avatar_url: avatar_url,
    bot: bot,
    id: id,
    name: name,
    object: object,
    person: person,
    type_: type_,
  ))
}

pub fn anon_84b72b7f_encode(data: Anon84b72b7f) {
  utils.object([
    #("avatar_url", json.nullable(data.avatar_url, json.string)),
    #("bot", json.nullable(data.bot, anon_fec5f02c_encode)),
    #("id", json.nullable(data.id, json.string)),
    #("name", json.nullable(data.name, json.string)),
    #("object", json.nullable(data.object, json.string)),
    #("person", json.nullable(data.person, anon_8818ae5d_encode)),
    #("type", json.nullable(data.type_, json.string)),
  ])
}
